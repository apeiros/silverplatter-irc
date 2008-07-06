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
		# Usually you'll not use Topic on its own but in conjunction
		# with a Channel. Also you should only read from a Topic, not
		# write to it.
		#
		# == Synopsis
		#   topic        = SilverPlatter::IRC::Topic.new
		#   topic.text   = "this is the topic of this channel"
		#   topic.set_by = "nickname"
		#   topic.set_at = Time.at(time_topic_was_set)
		#
		# == Attributes
		# SilverPlatter::IRC::Topic is a Struct with three attributes:
		# text::   The text of the topic.
		# set_by:: The nick of the user who set the current topic
		# set_at:: A Time instance of the time when the current topic was set
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
				sprintf "#<%s %s --%s on %s>",
					self.class,
					text,
					set_by,
					set_at.strftime("%Y-%m-%d %H:%M")
				# /sprintf
			end
		end
	end
end
