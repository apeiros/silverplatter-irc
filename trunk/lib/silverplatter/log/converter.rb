#--
# Copyright 2007 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module Log
	module Converter
		def default_type
			:info
		end

		def convert(obj)
			case obj
				when Entry:     obj
				when Exception:	Entry.new(obj.message.chomp, :error, obj.backtrace)
				else            Entry.new(obj.to_str.chomp, default_type)
			end
		end
	end
end
