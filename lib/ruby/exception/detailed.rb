#
class Exception

	# Extend an Exception with Exception::Detailed to add details to an
	# exception. Useful when rescuing lots of different exceptions and then
	# reraising a single type of exception.
	#
	module Detailed
		def self.extended(obj)
			obj.initialize_details
		end

		def initialize_details
			@prepend = []
			@append  = []
		end

		def prepend(string)
			(@prepend ||= []).unshift string
		end

		def append(string)
			(@append ||= []).unshift string
		end

		def to_s
			((@prepend||[])+[super]+(@append||[])).join(' ')
		end
	end
end
