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
		# SilverPlatter::IRC::Topic is used to store the topic (text,
		# nick of the user who set it, time it was set) of a channel.
		# 
		# == Known Bugs
		# Currently none.
		# Please inform me about bugs using the bugtracker on
		# http://rubyforge.org/tracker/?atid=17330&group_id=4522&func=browse
		#
		# == See Also
		# * SilverPlatter::IRC
		# * SilverPlatter::IRC::Channel
		# * http://www.faqs.org/rfcs/rfc1459.html Section 4.2.3.1
		class Topic < Struct.new(:text, :set_by, :set_at)
			def inspect
				"#<%s %s --%s on %s>" %  [
					self.class,
					text,
					set_by,
					set_at.strftime("%Y-%m-%d %H:%M")
				]
			end
		end
	end
end
