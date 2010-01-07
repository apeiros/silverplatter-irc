#--
# Copyright 2007 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module SilverPlatter
	module IRC

		# == Authors
		# * Stefan Rusterholz <apeiros@gmx.net>
		#
		# == About
		# Reply for SilverPlatter::IRC::Connection#whois
		# 
		# == Description
		# The attributes are:
		# connection:: to what connection this whois is bound
		# exists::     true if user exists, false if not, if false, all other attributes will be nil
		# nick::       nickname
		# user::       username
		# host::       hostname
		# real::       realname
		# registered:: whether the user is identified with nickserv or authserv, not all servers are
		#              currently supported
		# channels::   Array of channelnames the server reports for this user (not necessarily all he
		#              really is in - depends on privacy settings of the user and the channel)
		# idle::       seconds this user is idling
		# signon::     Time instance of when the user signed on to the server
		# 
		# == Known Bugs
		# Currently none.
		# Please inform me about bugs using the bugtracker on
		# http://rubyforge.org/tracker/?atid=17330&group_id=4522&func=browse
		#
		# == See Also
		# * SilverPlatter::IRC
		# * SilverPlatter::IRC::Connection
		# * SilverPlatter::IRC::User
		# * http://www.faqs.org/rfcs/rfc2812.html, Section 3.6.2 (Whois query)
		class Whois	< Struct.new(
				:connection,
				:exists,
				:nick,
				:user,
				:host,
				:real,
				:registered,
				:channels,
				:server,
				:idle,
				:signon
			)
		end
	end
end
