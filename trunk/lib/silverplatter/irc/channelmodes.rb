#--
# Copyright 2007 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'silverplatter/irc/rfc1459_channelmodes'



module SilverPlatter
	module IRC

		# == Authors
		# * Stefan Rusterholz <apeiros@gmx.net>
		#
		# == About
		# SilverPlatter::IRC::ChannelModes is used to store the modes a channel
		# has and the associated value if given.
		# 
		# == Known Bugs
		# Currently none.
		# Please inform me about bugs using the bugtracker on
		# http://rubyforge.org/tracker/?atid=17330&group_id=4522&func=browse
		#
		# == See Also
		# * SilverPlatter::IRC
		# * SilverPlatter::IRC::RFC1459_ChannelModes
		# * SilverPlatter::IRC::Connection
		# * SilverPlatter::IRC::Channel
		# * http://www.faqs.org/rfcs/rfc1459.html Section 4.2.3.1
		#
		# == TODO
		# Change implementation to use a String instead of a Hash.
		class ChannelModes
			include RFC1459_ChannelModes

			def initialize
				@modes = {}
			end
			
			# Add a mode with a value to this channel, for valueless modes the value is true.
			# The value will be frozen.
			def add(mode, value=true)
				@modes[mode] = value.freeze
			end

			# Remove a mode from this channel
			def remove(mode)
				@modes.delete(mode)
			end

			# Test whether the channel has a given mode set
			#   channel.mode.set?(IRC::RFC1459_ChannelModes::Private)
			def set?(value)
				@modes[value]
			end

			# Test whether this channel has the rfc1459 private flag (p) set
			def private?
				@modes[Private]
			end

			# Test whether this channel has the rfc1459 secret flag (s) set
			def secret?
				@modes[Secret]
			end
			
			# Test whether this channel has the rfc1459 invite only flag (i) set
			def invite_only?
				@modes[InviteOnly]
			end

			# Test whether this channel has the rfc1459 lock topic flag (t) set
			def locked_topic?
				@modes[LockedTopic]
			end

			# Test whether this channel has the rfc1459 members only may message flag (n) set
			def members_only?
				@modes[MembersOnly]
			end

			# Test whether this channel has the rfc1459 moderated flag (m) set
			def moderated?
				@modes[Moderated]
			end

			# Test whether this channel has the rfc1459 limit flag (l) set
			def limited?
				@modes[Limited]
			end

			# Test whether this channel has the rfc1459 password protected flag (k) set
			def password?
				@modes[Password]
			end
			
			def []=(mode, value=true)
				@modes[mode] = value
			end
			
			def method_missing(m, *args)
				super unless mode = @modes["#{m.to_s.sub(/\?$/, '')}"]
				raise ArgumentError, "#{args.size} for 0 arguments given" unless args.empty?
				mode
			end
			
			def to_hash
				@modes.dup
			end
			
			def __hash__
				@modes
			end
		end # ChannelModes
	end # IRC
end # SilverPlatter
