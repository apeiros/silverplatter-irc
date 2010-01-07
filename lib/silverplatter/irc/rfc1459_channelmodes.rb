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
		# SilverPlatter::IRC::RFC1459_ChannelModes provides constants containing
		# channel mode information according to rfc1459
		# 
		# == Known Bugs
		# Currently none.
		# Please inform me about bugs using the bugtracker on
		# http://rubyforge.org/tracker/?atid=17330&group_id=4522&func=browse
		#
		# == See Also
		# * SilverPlatter::IRC
		# * SilverPlatter::IRC::Connection
		# * SilverPlatter::IRC::Channel
		# * http://www.faqs.org/rfcs/rfc1459.html Section 4.2.3.1
		module RFC1459_ChannelModes
			# Private channel, 'p' flag
			Private     = "p".freeze

			# Secret channel, 's' flag
			Secret      = "s".freeze

			# Invite only channel, 'i' flag
			InviteOnly  = "i".freeze

			# Channel with locked topic, 'i' flag
			LockedTopic = "t".freeze

			# Only members of the channel may write to it, 'n' flag
			MembersOnly = "n".freeze

			# Moderated channel (only ops and voiced users may write), 'm' flag
			Moderated   = "m".freeze

			# Limited channel (only a limited amount of users allowed), 'l' flag
			Limited     = "l".freeze

			# Password protected channel, 'k' flag
			Password    = "k".freeze
		end # RFC1459_ChannelModes
	end # IRC
end # SilverPlatter
