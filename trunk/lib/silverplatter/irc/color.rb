#--
# Copyright 2007 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'silverplatter/irc/color/sequence'

module SilverPlatter
	module IRC

		# == Indexing
		# * Author:   Stefan Rusterholz
		# * Contact:  apeiros@gmx.net>
		# * Revision: $Revision: 144 $
		# * Date:     $Date: 2008-03-14 18:28:54 +0100 (Fri, 14 Mar 2008) $
		#
		# == About
		# 
		# 
		# == Synopsis
		#   module Kernel
		#     include SilverPlatter::IRC::Color
		#   end
		#   "#{red.on_yellow}Hello World!#{plain}"
		# 
		# == Description
		# ...
		#
		# == Known Bugs
		# Currently none
		# Please inform me about bugs using the bugtracker on
		# http://rubyforge.org/tracker/?atid=17330&group_id=4522&func=browse
		#
		# == See Also
		# * SilverPlatter::IRC
		# * SilverPlatter::IRC::Color::Sequence
		# * SilverPlatter::IRC::Color::String
		module Color
			Reset     = 3.chr.freeze
			Bold      = 2.chr.freeze
			Plain     = 15.chr.freeze
			Reverse   = 18.chr.freeze
			Underline = 31.chr.freeze
			Italic    = 29.chr.freeze
			Blink     = 9.chr.freeze # ?

			def color(code)
				Sequence.new(code)
			end

			def on_color(code)
				Sequence.new(nil, code)
			end
			
			def plain
				Sequence.new(nil, nil, Plain)
			end
			
			def bold
				Sequence.new(nil, nil, Bold)
			end
			
			def reverse
				Sequence.new(nil, nil, Reverse)
			end
			
			def underline
				Sequence.new(nil, nil, Underline)
			end
			
			def italic
				Sequence.new(nil, nil, Italic)
			end
			
			def blink
				Sequence.new(nil, nil, Blink)
			end

			def white
				Sequence.new(0)
			end
			
			def black
				Sequence.new(1)
			end
			
			def blue
				Sequence.new(2)
			end
			
			def green
				Sequence.new(3)
			end
			
			def red
				Sequence.new(4)
			end
			
			def brown
				Sequence.new(5)
			end
			
			def purple
				Sequence.new(6)
			end
			
			def orange
				Sequence.new(7)
			end
			
			def yellow
				Sequence.new(8)
			end
			
			def ltgreen
				Sequence.new(9)
			end

			def teal
				Sequence.new(10)
			end
			
			def ltcyan
				Sequence.new(11)
			end
			
			def ltblue
				Sequence.new(12)
			end
			
			def pink
				Sequence.new(13)
			end
			
			def grey
				Sequence.new(14)
			end
			
			def ltgrey
				Sequence.new(15)
			end

			def on_white
				Sequence.new(nil, 0)
			end
			
			def on_black
				Sequence.new(nil, 1)
			end
			
			def on_blue
				Sequence.new(nil, 2)
			end
			
			def on_green
				Sequence.new(nil, 3)
			end
			
			def on_red
				Sequence.new(nil, 4)
			end
			
			def on_brown
				Sequence.new(nil, 5)
			end
			
			def on_purple
				Sequence.new(nil, 6)
			end
			
			def on_orange
				Sequence.new(nil, 7)
			end
			
			def on_yellow
				Sequence.new(nil, 8)
			end
			
			def on_ltgreen
				Sequence.new(nil, 9)
			end

			def on_teal
				Sequence.new(nil, 10)
			end
			
			def on_ltcyan
				Sequence.new(nil, 11)
			end
			
			def on_ltblue
				Sequence.new(nil, 12)
			end
			
			def on_pink
				Sequence.new(nil, 13)
			end
			
			def on_grey
				Sequence.new(nil, 14)
			end
			
			def on_ltgrey
				Sequence.new(nil, 15)
			end
		end # Color
	end # IRC
end # SilverPlatter
