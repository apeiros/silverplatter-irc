#--
# Copyright 2007 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++

# This file is instance_eval'ed on a SilverPlatter::IRC::Parser, so see there for
# available methods

# --- Text based ----------------------------------------
add("error",   :ERROR)		# ERROR :<error-message>
add("invite",  :INVITE, /^(\S*) :(.*)/, [:invited, :channel])
add("join",    :JOIN,   /^:(.*)/, [:channel]) { |connection, message, fields|
	from    = message.from
	channel = message.channel
	if from && channel then
		from.add_channel(channel, :join)
		channel.add_user(from,   :join)
		if from.me? then
			# advantage of doing it here: it is done after join (who might fail otherwise),
			# disatvantage: +1 condition for every join
			connection.send_mode(channel)
			connection.send_who(channel)
		elsif from.change_visibility(true) then
			# FIXME: inform UserManager
		end
	end
}
add("kick",    :KICK,   /^(\S*) (\S*) :(.*)/, [:channel, :recipient, :text]) { |connection, message, fields|
	connection.leave_channel(message, :kick, :kicked)
}
add("kill",    :KILL,   /^(\S*) (\S*) (.*)/, [:channel, :recipient, :text]) { |connection, message, fields|
	connection.leave_server(message, message.recipient, :kill, :killed)
}
# FIXME, take another look at this (code, isupport)
add("mode",    :MODE,   /^(\S*) (.*)/, [:recipient, :arguments]) { |connection, message, fields|
	modifiers       = message[:arguments].split(" ")
	modes           = modifiers.shift.split("")
	flags           = {"o" => User::Op, "v" => User::Voice, "u" => User::Uop}
	message[:modes] = []
	argument_index  = 0
	direction       = "+"
	channel         = message.channel

	modes.each { |mode|
		# MODEs direction
		if (%w[+ -].include?(mode)) then
			direction	= mode
		# MODEs taking an argument
		elsif ("kovu".include?(mode) || (mode == "l" && direction == "+")) then
			if "ovu".include?(mode) then
				if (direction == "+") then
					connection.users.by_nick(modifiers[argument_index]).add_flag(channel, flags[mode]) #adding flags to user
				else
					connection.users.by_nick(modifiers[argument_index]).delete_flag(channel, flags[mode]) #removing flags from user
				end
			end
			message.modes << [direction, mode, modifiers[argument_index]]
			argument_index += 1
		# MODEs without argument
		else
			message.modes << [direction, mode, nil]
		end
	}
}
add("nick",    :NICK,    /^:?(.*)/, [:nick]) { |connection, message, fields|
	message[:old_nick] = message.from.nick
	connection.update_user(message.from, message.nick) if message.from
}
add("notice",  :NOTICE,  /(\S+) :(.*)/, [:recipient, :text]) { |connection, message, fields|
	if connection.msg_identify then
		message.instance_variable_set(:@identified, message.text.slice!(/^[+-]/) == '+')
	end
}
add("part",    :PART,    /^([^\x00\x07\x10\x0D\x20,:]+)(?: :(.*))?/, [:channel, :reason]) { |connection, message, fields|
	connection.leave_channel(message, :part, :parted)
}
add("ping",    :PING,    /^:?(.*)/, [:pong]) { |connection, message, fields|
	connection.send_pong(fields[:pong])
}
add("pong",    :PONG)
add("privmsg", :PRIVMSG, /(\S+) :(.*)/, [:recipient, :text]) { |connection, message, fields|
	if connection.msg_identify then
		message.instance_variable_set(:@identified, message.text.slice!(/^[+-]/) == '+')
		# FIXME: inform UserManager if message.from.invisible?
	end
}
add("quit",    :QUIT,    /(.*)/, [:text]) { |connection, message, fields|
	connection.leave_server(message, message.from, :quit, :quitted)
}
add("topic",   :TOPIC, /(\S+) :(.*)/, [:channel, :text])



# --- 0** Codes ----------------------------------------
add("001", :RPL_WELCOME)
add("002", :RPL_YOURHOST)
add("003", :RPL_CREATED)
add("004", :RPL_MYINFO, /(\S+) (\S+) (\S+) (\S+)/, [:servername, :version, :user_modes, :channel_modes])
add("005", :RPL_BOUNCE)




# --- 2** Codes ----------------------------------------
add("200", :RPL_TRACELINK)
add("201", :RPL_TRACECONNECTING)
add("202", :RPL_TRACEHANDSHAKE)
add("203", :RPL_TRACEUNKNOWN)
add("204", :RPL_TRACEOPERATOR)
add("205", :RPL_TRACEUSER)
add("206", :RPL_TRACESERVER)
add("207", :RPL_TRACESERVICE)
add("208", :RPL_TRACENEWTYPE)
add("209", :RPL_TRACECLASS)
add("210", :RPL_TRACERECONNECT)
add("211", :RPL_STATSLINKINFO)
add("212", :RPL_STATSCOMMANDS)
add("213", :RPL_STATSCLINE)
add("214", :RPL_STATSNLINE)
add("215", :RPL_STATSILINE)
add("216", :RPL_STATSKLINE)
add("217", :RPL_STATSQLINE)
add("218", :RPL_STATSYLINE)
add("219", :RPL_ENDOFSTATS)

add("221", :RPL_UMODEIS)

add("231", :RPL_SERVICEINFO)
add("232", :RPL_ENDOFSERVICES)
add("233", :RPL_SERVICE)
add("234", :RPL_SERVLIST)
add("235", :RPL_SERVLISTEND)

add("240", :RPL_STATSVLINE)
add("241", :RPL_STATSLLINE)
add("242", :RPL_STATSUPTIME)
add("243", :RPL_STATSOLINE)
add("244", :RPL_STATSHLINE)
add("245", :RPL_STATSSLINE)	# RFC 2812 seems to be erroneous, it assigns 244 double
add("246", :RPL_STATSPING)
add("247", :RPL_STATSBLINE)
add("250", :RPL_STATSCONN)
add("251", :RPL_LUSERCLIENT)
add("252", :RPL_LUSEROP)
add("253", :RPL_LUSERUNKNOWN)
add("254", :RPL_LUSERCHANNELS)
add("255", :RPL_LUSERME)
add("256", :RPL_ADMINME)
add("257", :RPL_ADMINLOC1)
add("258", :RPL_ADMINLOC2)
add("259", :RPL_ADMINEMAIL)

add("261", :RPL_TRACELOG)
add("262", :RPL_TRACEEND)

add("263", :RPL_TRYAGAIN)



# --- 3** Codes ----------------------------------------
add("300", :RPL_NONE)
add("301", :RPL_AWAY)
add("302", :RPL_USERHOST)
add("303", :RPL_ISON)
add("305", :RPL_UNAWAY)
add("306", :RPL_NOWAWAY)
add("311", :RPL_WHOISUSER, /^(\S+) (\S+) (\S+) (\S+) \* :(.*)/, [:recipient, :nick, :user, :host, :real])
add("312", :RPL_WHOISSERVER)
add("313", :RPL_WHOISOPERATOR)
add("314", :RPL_WHOWASUSER)
add("315", :RPL_ENDOFWHO)
add("316", :RPL_WHOISCHANOP)
add("317", :RPL_WHOISIDLE, /^(\S+) (\S+) ([^:]+) :(.*)/, [:recipient, :nick, :values, :descriptions]) { |connection, message, fields|
	values			= message[:values].split(" ");
	descriptions	= message[:descriptions].split(", ").map { |desc| desc.gsub(" ", "_").to_sym };
	message.delete(:values)
	message.delete(:descriptions)
	0.upto([values.length, descriptions.length].min-1) { |index|
		message[descriptions[index]]	= values[index]
	}
}
add("318", :RPL_ENDOFWHOIS)
add("319", :RPL_WHOISCHANNELS, /^(\S+) (\S+) :(.*)/, [:recipient, :nick, :channels]) # only add channels shared with butler to a user - that happens elsewhere already
add("321", :RPL_LISTSTART)
add("322", :RPL_LIST, /^(\S+) (\S+) (\d+) :(.*)/, [:recipient, :channelname, :usercount, :topic])
add("323", :RPL_LISTEND)
add("324", :RPL_CHANNELMODEIS)
add("325", :RPL_UNIQOPIS)
add("331", :RPL_NOTOPIC)
		# :irc.server.net 332 YourNickname #channel :Topic
add("332", :RPL_TOPIC, /^(\S+) (\S+) :(.*)/, [:recipient, :channel, :topic]) { |connection, message, fields|
	message.channel.topic.text = message[:topic]
}
add("341", :RPL_INVITING)
add("342", :RPL_SUMMONING)
add("346", :RPL_INVITELIST)
add("347", :RPL_ENDOFINVITELIST)
add("348", :RPL_EXCEPTLIST)
add("349", :RPL_ENDOFEXCEPTLIST)
add("351", :RPL_VERSION)
		# :irc.server.net 352 YourNickname <channel> <user> <host> <server> <nick> ( "H" / "G" > ["*"] [ ( "@" / "+" ) ] :<hopcount> <real name>
add("352", :RPL_WHOREPLY,
			/(\S+) (\S+) (\S+) (\S+) (\S+) (\S+) ([HG])\*?(#{expression.who_flags}) :(\d+) (.*)/,
			[:recipient, :channel, :user, :host, :server, :nick, :status, :flags, :hopcount, :real]) { |connection, message, fields|
#"for", "channel", "user", "host", "server", "nick", "status", "flags", "hopcount", "real"
	user	= connection.create_user(message[:nick])
	connection.update_user(user, message[:nick], message[:user], message[:host], message[:real])
	user.away	= message[:status] == "G"
	user.add_channel(message.channel, :joined)
	message.channel.add_user(user, :joined)
	user.add_flags(message.channel, message[:flags])
}
add("353", :RPL_NAMEREPLY, /(\S+) [=@*] (\S+) :(.*)/, [:recipient, :channel, :users]) { |connection, message, fields|
	users            = fields[:users]
	delete_who_flags = connection.parser.expression.delete_who_flags
	
	message[:users] = users.split(/ /).map { |nick|
		user	= connection.create_user(nick.sub(delete_who_flags, ''))
		user.add_channel(message.channel, :joined)
		message.channel.add_user(user, :joined)
		user
	}
}
add("361", :RPL_KILLDONE)
add("362", :RPL_CLOSING)
add("363", :RPL_CLOSEEND)
add("364", :RPL_LINKS)
add("365", :RPL_ENDOFLINKS)
add("366", :RPL_ENDOFNAMES)
add("367", :RPL_BANLIST,
			/(\S+) (\S+) (\S+) (\S+) (\d+)/,
			[:recipient, :channel, :banmask, :banned_by, :bantime]
) { |connection, message, fields| #367 nickname #channel nick!user@host nickname 1140125288
	message[:bantime]	= Time.at(message[:bantime].to_i)
	message[:banmask]	= Hostmask.new(message[:banmask])
}
add("369", :RPL_ENDOFWHOWAS)

add("368", :RPL_ENDOFBANLIST)
add("371", :RPL_INFO)
add("372", :RPL_MOTD)
add("373", :RPL_INFOSTART)
add("374", :RPL_ENDOFINFO)
add("375", :RPL_MOTDSTART)
add("376", :RPL_ENDOFMOTD)
add("381", :RPL_YOUREOPER)
add("382", :RPL_REHASHING)
add("383", :RPL_YOURESERVICE)
add("384", :RPL_MYPORTIS)
add("391", :RPL_TIME)
add("392", :RPL_USERSSTART)
add("393", :RPL_USERS)
add("394", :RPL_ENDOFUSERS)
add("395", :RPL_NOUSERS)



# --- 4** Codes ----------------------------------------
add("401", :ERR_NOSUCHNICK)
add("402", :ERR_NOSUCHSERVER)
add("403", :ERR_NOSUCHCHANNEL)
add("404", :ERR_CANNOTSENDTOCHAN)
add("405", :ERR_TOOMANYCHANNELS)
add("406", :ERR_WASNOSUCHNICK)
add("407", :ERR_TOOMANYTARGETS)
add("408", :ERR_NOSUCHSERVICE)
add("409", :ERR_NOORIGIN)
add("411", :ERR_NORECIPIENT)
add("412", :ERR_NOTEXTTOSEND)
add("413", :ERR_NOTOPLEVEL)
add("414", :ERR_WILDTOPLEVEL)
add("415", :ERR_BADMASK)
add("421", :ERR_UNKNOWNCOMMAND)
add("422", :ERR_NOMOTD)
add("423", :ERR_NOADMININFO)
add("424", :ERR_FILEERROR)
add("431", :ERR_NONICKNAMEGIVEN)
add("432", :ERR_ERRONEUSNICKNAME)
add("433", :ERR_NICKNAMEINUSE) { |connection, message, fields|
	connection.event(:nick_error, message)
}
add("436", :ERR_NICKCOLLISION)
add("437", :ERR_UNAVAILRESOURCE)
add("441", :ERR_USERNOTINCHANNEL)
add("442", :ERR_NOTONCHANNEL)
add("443", :ERR_USERONCHANNEL)
add("444", :ERR_NOLOGIN)
add("445", :ERR_SUMMONDISABLED)
add("446", :ERR_USERSDISABLED)
add("451", :ERR_NOTREGISTERED)
add("461", :ERR_NEEDMOREPARAMS)
add("462", :ERR_ALREADYREGISTRED)
add("463", :ERR_NOPERMFORHOST)
add("464", :ERR_PASSWDMISMATCH)
add("465", :ERR_YOUREBANNEDCREEP)
add("466", :ERR_YOUWILLBEBANNED)
add("467", :ERR_KEYSET)
add("471", :ERR_CHANNELISFULL)
add("472", :ERR_UNKNOWNMODE)
add("473", :ERR_INVITEONLYCHAN)
add("474", :ERR_BANNEDFROMCHAN)
add("475", :ERR_BADCHANNELKEY)
add("476", :ERR_BADCHANMASK)
add("477", :ERR_NOCHANMODES)
add("478", :ERR_BANLISTFULL)
add("481", :ERR_NOPRIVILEGES)
add("482", :ERR_CHANOPRIVSNEEDED)
add("483", :ERR_CANTKILLSERVER)
add("484", :ERR_RESTRICTED)
add("485", :ERR_UNIQOPPRIVSNEEDED)
add("491", :ERR_NOOPERHOST)
add("492", :ERR_NOSERVICEHOST)



# --- 5** Codes ----------------------------------------
add("501", :ERR_UMODEUNKNOWNFLAG)
add("502", :ERR_USERSDONTMATCH)
