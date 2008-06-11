#--
# Copyright 2007 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'log/fakeio'
require 'log/converter'



module Log
	# Log.forward is equivalent to Log::Forward.new
	def self.forward(*args)
		Forward.new(*args)
	end

	# Forward an IO to an object (object must respond to #puts)
	# Will convert all puts/prints etc. to Log::Entry's using
	# Log::Converter#convert
	# Example:
	#   $stderr = Log.forward(your_logfile)
	class Forward
		include FakeIO
		include Converter

		def initialize(to, type=:info)
			raise ArgumentError, "Target must respond to 'puts'" unless to.respond_to?(:puts)
			@to           = to
			@default_type = type
			@buffer       = ""
		end
		
		def process(obj)
			@to.puts(obj)
		end
		
		def inspect
			"#<%s:%08x %s %s>" %  [
				self.class,
				object_id,
				@default_type,
				@to.inspect
			]
		end
	end
end