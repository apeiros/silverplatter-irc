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
		# SilverPlatter::IRC::RFC1459_UserModes provides constants containing
		# user mode information according to rfc1459
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
		# * 
		module RFC1459_UserModes
			# Op prefix
			Op    = "o".freeze

			# Uop prefix
			Uop   = "u".freeze

			# Voice prefix
			Voice = "v".freeze
			
			# Valid flags as per RFC2812
			UserModes = "ov".freeze
			
			# Default for flags
			NoModes = "".freeze
		end # RFC1459_UserModes
	end # IRC
end # SilverPlatter
