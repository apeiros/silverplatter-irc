#--
# Copyright 2007 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++

# This file is instance_eval'ed on a SilverPlatter::IRC::Parser, so see there for
# available methods

alter("005", :ISUPPORT) { |connection, message, fields|
	hash = {}
	message.params.sub(/\s+:.*?$/, '').split(/ /)[1..-1].each { |support|
		name, value = support.split(/=/,2)
		hash[name.downcase.to_sym]  = case name
			when "CAPAB"
				true
			when *%w[CHANNELLEN NICKLEN MAXCHANNELS MODES TOPICLEN USERLEN KEYLEN]
				value.to_i
			when "PREFIX"
				modes, prefixes = value[1..-1].split(/\)/, 2)
				value = {}
				modes.split(//).zip(prefixes.split(//)) { |k,v| value[k] = v }
				value
			else value
		end
	}
	isupport            = connection.isupport.__hash__.merge(hash)
	isupport[:prefixes] = isupport[:prefix].values.join('') if isupport.has_key?(:prefix)

	connection.use_casemapping(hash[:casemapping]) if hash[:casemapping]
	connection.write_with_eol("CAPAB IDENTIFY-MSG") if (connection.isupport.capab && !connection.msg_identify)
	connection.parser.reset(isupport)

	message[:support] = hash
}

# Seen:
#   - ConferenceRoom (irc.bluewin.ch)
add("007", :UNK_007)

# Seen:
#   - ConferenceRoom (irc.bluewin.ch)
add("008", :UNK_008)

# Seen:
#   - ConferenceRoom (irc.bluewin.ch)
add("009", :UNK_009)

add("265", :RPL_LOCALUSERS)
add("266", :RPL_GLOBALUSERS)

# Seen:
#   - hyperion-1.0.2b (irc.freenode.net)
#   States what kind of messages will be identified
add("290", :RPL_IDENTIFY_MSG, /(\S+) :?(.*)/, [:nick, :types]) { |connection, message, fields|
	types = {}
	message[:types].scan(/\S+/).each { |k| types[k] = true }
	message[:types] = types
	connection.parser.msg_identify ||= types["IDENTIFY-MSG"]
}

# Seen:
#  - ConferenceRoom (irc.bluewin.ch), sent if a nick is registered
add("307", :RPL_REGISTERED_INFO)	
add("320", :RPL_IDENTIFIED_TO_SERVICES) # possibly hyperion only
add("328", :UNK_328)		# freenode.net, on join
add("329", :RPL_CHANNEL_INFO)		#channel creation time

# :irc.server.net 333 YourNickname #channel SetByNick 1139902138
add("333", :RPL_TOPIC_INFO, /^(\S+) (\S+) (\S+) (\d+)/, [:for, :channel, :set_by, :set_at]) { |connection, message, fields|
	topic = message.channel.topic
	topic.set_by = message[:set_by]
	topic.set_at = message[:set_at]
}
add("343", :RPL__MAINTENANCE)	#mainenance notice?
add("377", :UNK_377)


add("386", :RPL_PASSWORDACCEPTED) # Custom (chatroom)

# Seen:
#   - ircu (undernet)
add("396", :RPL_HOSTHIDDEN, /^(\S+) (?:(.*?)@)?([:\S]+) :(.*)/, [:nick, :user, :displayed_host, :text]) { |connection, message, fields|
	connection.myself.update(nil, message.displayed_host, nil)
}

add("410", :ERR_SERVICES_OFFLINE)

add("505", :ERR_NOPRIVMSG)

add("901", :UNK_901) # logged in confirmation on freenode
