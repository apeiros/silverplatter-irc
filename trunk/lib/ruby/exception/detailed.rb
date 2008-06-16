class Exception
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