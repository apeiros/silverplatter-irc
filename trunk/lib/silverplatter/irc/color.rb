#--
# Copyright 2007 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'silverplatter/irc/color/sequence'



module SilverPlatter
	module IRC

		# == Authors
		# * Stefan Rusterholz <apeiros@gmx.net>
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
			# The code to reset formatting
			Reset     = 3.chr.freeze
			
			# The code to switch bold on
			Bold      = 2.chr.freeze
			
			# The code to switch plain on
			Plain     = 15.chr.freeze
			
			# The code to switch reversing on
			Reverse   = 18.chr.freeze
			
			# The code to switch underline on
			Underline = 31.chr.freeze
			
			# The code to switch italic on
			Italic    = 29.chr.freeze
			
			# The code to switch blinking on
			Blink     = 9.chr.freeze # ?



			# Foreground color with the given code. Code is 0-15.
			# The codes translate to:
			# *  0: white
			# *  1: black
			# *  2: blue
			# *  3: green
			# *  4: red
			# *  5: brown
			# *  6: purple
			# *  7: orange
			# *  8: yellow
			# *  9: light green
			# * 10: teal
			# * 11: light cyan
			# * 12: light blue
			# * 13: pink
			# * 14: grey
			# * 15: light grey
			# For every color code there's a named method too.
			def color(code)
				Sequence.new(code)
			end

			# Background color with the given code. Code is 0-15.
			# The codes translate to:
			# *  0: white
			# *  1: black
			# *  2: blue
			# *  3: green
			# *  4: red
			# *  5: brown
			# *  6: purple
			# *  7: orange
			# *  8: yellow
			# *  9: light green
			# * 10: teal
			# * 11: light cyan
			# * 12: light blue
			# * 13: pink
			# * 14: grey
			# * 15: light grey
			# For every color code there's a named method too.
			def on_color(code)
				Sequence.new(nil, code)
			end
			
			# Set coloring back to plain
			def plain
				Sequence.new(nil, nil, Plain)
			end
			
			# Set the font to bold
			def bold
				Sequence.new(nil, nil, Bold)
			end
			
			# Set the text to be reversed
			def reverse
				Sequence.new(nil, nil, Reverse)
			end
			
			# Set the font to be underlined
			def underline
				Sequence.new(nil, nil, Underline)
			end
			
			# Set the font to italic
			def italic
				Sequence.new(nil, nil, Italic)
			end
			
			# Set the text to blink
			def blink
				Sequence.new(nil, nil, Blink)
			end

			# White foreground color
			def white
				Sequence.new(0)
			end
			
			# Black foreground color
			def black
				Sequence.new(1)
			end
			
			# Blue foreground color
			def blue
				Sequence.new(2)
			end
			
			# Green foreground color
			def green
				Sequence.new(3)
			end
			
			# Red foreground color
			def red
				Sequence.new(4)
			end
			
			# Brown foreground color
			def brown
				Sequence.new(5)
			end
			
			# Purple foreground color
			def purple
				Sequence.new(6)
			end
			
			# Orange foreground color
			def orange
				Sequence.new(7)
			end
			
			# Yellow foreground color
			def yellow
				Sequence.new(8)
			end
			
			# Light green foreground color
			def ltgreen
				Sequence.new(9)
			end

			# Teal foreground color
			def teal
				Sequence.new(10)
			end
			
			# Light cyan foreground color
			def ltcyan
				Sequence.new(11)
			end
			
			# Light blue foreground color
			def ltblue
				Sequence.new(12)
			end
			
			# Pink foreground color
			def pink
				Sequence.new(13)
			end
			
			# Grey foreground color
			def grey
				Sequence.new(14)
			end
			
			# Light grey foreground color
			def ltgrey
				Sequence.new(15)
			end

			# White background color
			def on_white
				Sequence.new(nil, 0)
			end
			
			# Black background color
			def on_black
				Sequence.new(nil, 1)
			end
			
			# Blue background color
			def on_blue
				Sequence.new(nil, 2)
			end
			
			# Green background color
			def on_green
				Sequence.new(nil, 3)
			end
			
			# Red background color
			def on_red
				Sequence.new(nil, 4)
			end
			
			# Brown background color
			def on_brown
				Sequence.new(nil, 5)
			end
			
			# Purple background color
			def on_purple
				Sequence.new(nil, 6)
			end
			
			# Orange background color
			def on_orange
				Sequence.new(nil, 7)
			end
			
			# Yellow background color
			def on_yellow
				Sequence.new(nil, 8)
			end
			
			# Light green background color
			def on_ltgreen
				Sequence.new(nil, 9)
			end

			# Teal background color
			def on_teal
				Sequence.new(nil, 10)
			end
			
			# Light cyan background color
			def on_ltcyan
				Sequence.new(nil, 11)
			end
			
			# Light blue background color
			def on_ltblue
				Sequence.new(nil, 12)
			end
			
			# Pink background color
			def on_pink
				Sequence.new(nil, 13)
			end
			
			# Grey background color
			def on_grey
				Sequence.new(nil, 14)
			end
			
			# Light grey background color
			def on_ltgrey
				Sequence.new(nil, 15)
			end
		end # Color
	end # IRC
end # SilverPlatter
