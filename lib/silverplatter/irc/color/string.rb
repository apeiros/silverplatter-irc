#--
# Copyright 2007 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module SilverPlatter
	module IRC
		module Color

			# == Authors
			# * Stefan Rusterholz <apeiros@gmx.net>
			#
			# == About
			# Add the String#colorized method to String
			# 
			# == Synopsis
			#   class String
			#      include SilverPlatter::IRC::Color::String
			#   end
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
			module String
				IRCColorReset     = 3.chr.freeze
				IRCColorBold      = 2.chr.freeze
				IRCColorPlain     = 15.chr.freeze
				IRCColorReverse   = 18.chr.freeze
				IRCColorUnderline = 31.chr.freeze
				IRCColorItalic    = 29.chr.freeze
				IRCColorBlink     = 9.chr.freeze # ?
				IRCColors         = %w[
					white
					black
					blue
					green
					red
					brown
					purple
					orange
					yellow
					ltgreen
					teal
					ltcyan
					ltblue
					pink
					grey
					ltgrey
				].map { |e| e.freeze }.freeze
				IRCOnColors = IRCColors.map { |e| "on_#{e}".freeze }.freeze
				IRCColorPatternSingle = /
					(?:
						(?:
							(?:on_)?(?:#{IRCColors.join('|')}|color\(\d{1,2}\))
						)|
						bold|italic|underline|blink|reverse|plain|reset
					)
				/x
				IRCColorPatternMulti  = /\#\{#{IRCColorPatternSingle}(?:\.#{IRCColorPatternSingle})*\}/
				
				# === Synopsis
				#   '#{red.on_yellow.bold}Hello World!#{plain}'.colorized
				#
				def colorized
					gsub(IRCColorPatternMulti) { |found|
						fg,bg = nil, nil
						flags = ""
						found[2..-2].split(/\./).each { |capture|
							cfg = IRCColors.index(capture)
							cbg = IRCOnColors.index(capture)
							fg ||= cfg
							bg ||= cbg
							unless cfg || cbg then
								case capture
									when "bold":       flags << IRCColorBold
									when "italic":     flags << IRCColorItalic
									when "underline":  flags << IRCColorUnderline
									when "blink":      flags << IRCColorBlink
									when "reverse":    flags << IRCColorReverse
									when "plain":      flags << IRCColorPlain
									when "reset":      flags << IRCColorReset
									when /color\((\d{1,2})\)/:    fg = $1.to_i
									when /on_color\((\d{1,2})\)/: bg = $1.to_i
									else
										raise "Parsing error"
								end
							end
						}
						if fg || bg then
							flags << IRCColorReset
							flags << fg.to_s if fg
							flags << ",#{bg}" if bg
						end
						flags
					}
				end # colorized
			end # String
		end # Color
	end # IRC
end # SilverPlatter
