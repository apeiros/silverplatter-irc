#--
# Copyright 2007 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++

# This file is instance_eval'ed on a SilverPlatter::IRC::Parser, so see there for
# available methods

isupport = proc { |connection, message, fields|
	hash = {}
	message.params.each { |support|
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
rpl_identify_msg = proc { |connection, message, fields|
	types = {}
	message[:types].scan(/\S+/).each { |k| types[k] = true }
	message[:types] = types
	connection.parser.msg_identify ||= types["IDENTIFY-MSG"]
}
rpl_channel_info = proc { |connection, message, fields|
	message.channel.created_at = Time.at(fields[:created_at])
}
rpl_topic_info = proc { |connection, message, fields|
	topic = message.channel.topic
	topic.set_by = message[:set_by]
	topic.set_at = message[:set_at]
}
rpl_host_hidden = proc { |connection, message, fields|
	connection.myself.update(nil, message.displayed_host, nil)
}



alter("005", :ISUPPORT, &isupport) # various

add("007", :UNK_007) # irc.bluewin.ch [ConferenceRoom]
add("008", :UNK_008) # irc.bluewin.ch [ConferenceRoom]
add("009", :UNK_009) # irc.bluewin.ch [ConferenceRoom]
add("265", :RPL_LOCALUSERS)
add("266", :RPL_GLOBALUSERS)
add("290", :RPL_IDENTIFY_MSG, :nick, :types, &rpl_identify_msg) # irc.freenode.org [hyperion-1.0.2b]: States what kind of messages will be identified
add("307", :RPL_REGISTERED_INFO) # irc.bluewin.ch [ConferenceRoom]: sent on whois if a nick is registered
add("320", :RPL_IDENTIFIED_TO_SERVICES) # possibly hyperion only
add("328", :UNK_328) # freenode.net, on join
add("329", :RPL_CHANNEL_INFO, :recipient, :channel, :created, &rpl_channel_info) #channel creation time
add("333", :RPL_TOPIC_INFO, :for, :channel, :set_by, :set_at, &rpl_topic_info)
add("343", :RPL__MAINTENANCE)	#mainenance notice?
add("377", :UNK_377)
add("386", :RPL_PASSWORDACCEPTED) # irc.bluewin.ch [ConferenceRoom]
add("396", :RPL_HOSTHIDDEN, :nick, :user, :displayed_host, :text, &rpl_host_hidden) # undernet [ircu]: when hiding host is activated
add("410", :ERR_SERVICES_OFFLINE)
add("505", :ERR_NOPRIVMSG)
add("901", :UNK_901) # irc.freenode.net: response to identification (/msg nickserv identify <pass>)
