#--
# Copyright 2007 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module SilverPlatter
	module IRC
		module Color

			# == Indexing
			# * Author:   Stefan Rusterholz
			# * Contact:  apeiros@gmx.net>
			# * Revision: $Revision: 145 $
			# * Date:     $Date: 2008-03-14 18:29:06 +0100 (Fri, 14 Mar 2008) $
			#
			# == About
			# Add methods to
			# 
			# == Synopsis
			#   module Kernel
			#      include SilverPlatter::IRC::Color
			#   end
			#   irc.send_privmsg("#{red.on_yellow.bold}Hello World!#{plain}", "#somechannel")
			#
			# == Description
			# 
			#
			# == Known Bugs
			# Currently none.
			# Please inform me about bugs using the bugtracker on
			# http://rubyforge.org/tracker/?atid=17330&group_id=4522&func=browse
			#
			# == See Also
			# * SilverPlatter::IRC
			# * SilverPlatter::IRC::Color
			#
			class Sequence
				EmptyString = "".freeze

				def initialize(fg=nil, bg=nil, *other)
					@fg    = fg
					@bg    = bg
					@other = other
				end
				
				def white
					@fg = 0
				end
				
				def black
					@fg = 1
				end
				
				def blue
					@fg = 2
				end
				
				def green
					@fg = 3
				end
				
				def red
					@fg = 4
				end
				
				def brown
					@fg = 5
				end
				
				def purple
					@fg = 6
				end
				
				def orange
					@fg = 7
				end
				
				def yellow
					@fg = 8
				end
				
				def ltgreen
					@fg = 9
				end
	
				def teal
					@fg = 10
				end
				
				def ltcyan
					@fg = 11
				end
				
				def ltblue
					@fg = 12
				end
				
				def pink
					@fg = 13
				end
				
				def grey
					@fg = 14
				end
				
				def ltgrey
					@fg = 15
				end

				def on_white
					@bg = 0
				end
				
				def on_black
					@bg = 1
				end
				
				def on_blue
					@bg = 2
				end
				
				def on_green
					@bg = 3
				end
				
				def on_red
					@bg = 4
				end
				
				def on_brown
					@bg = 5
				end
				
				def on_purple
					@bg = 6
				end
				
				def on_orange
					@bg = 7
				end
				
				def on_yellow
					@bg = 8
				end
				
				def on_ltgreen
					@bg = 9
				end
	
				def on_teal
					@bg = 10
				end
				
				def on_ltcyan
					@bg = 11
				end
				
				def on_ltblue
					@bg = 12
				end
				
				def on_pink
					@bg = 13
				end
				
				def on_grey
					@bg = 14
				end
				
				def on_ltgrey
					@bg = 15
				end
				
				def on_color(val)
					raise ArgumentError unless val.between?(0,15)
					@bg = val
				end
				
				def plain
					@other << Plain
				end
				
				def bold
					@other << Bold
				end
				
				def reverse
					@other << Reverse
				end
				
				def underline
					@other << Underline
				end
				
				def italic
					@other << Italic
				end
				
				def blink
					@other << Blink
				end
	
				def to_s
					out  = @other.join(EmptyString)
					if @fg || @bg then
						out << Reset 
						out << ("%d" %  @fg) if @fg # %02d IMO, but seems MIRC team FU on this one
						out << (",%d" %  @bg) if @bg # %02d IMO, but seems MIRC team FU on this one
					end
				end
			end # Sequence
		end # Color
	end # IRC
end # SilverPlatter
