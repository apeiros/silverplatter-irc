#--
# Copyright 2007 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module SilverPlatter
	module IRC
		# This module is included in the String-class and provides some methods helping with irc
		# related issues.
		module StringHelpers
			# Regular expression matching all mirc formatting codes
			MIRCFormatting = /(?:[\x02\x0f\x12\x1f\x1d\x09]|\cc\d{1,2}(?:,\d{1,2})?)/ unless const_defined?(:MIRCFormatting)
			EmptyString    = "".freeze unless const_defined?(:EmptyString)
		
			# See SilverPlatter::IRC::Socket#send_join
			# Also works correctly with nil for no password.
			def with_password(pass=nil)
				pass ? [self, pass] : self
			end
			
			# Returns a string with all mirc formatting codes stripped.
			def strip_formatting
				gsub(MIRCFormatting, EmptyString)
			end
		
			# Strips all mirc formatting codes from this string.
			# Returns nil if nothing changed.
			def strip_formatting!
				gsub!(MIRCFormatting, EmptyString)
			end
		end # StringHelpers
	end # IRC
end # SilverPlatter

class String
	include SilverPlatter::IRC::StringHelpers
end
