#--
# Copyright 2007 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'log/converter'
require 'log/fakeio'
require 'log/methods'



module Log
	# Log.file is equivalent to Log::File.new
	def self.file(*args)
		Log::File.new(*args)
	end

	class File
		include Converter
		include FakeIO
		include Methods

		def initialize(out)
			@out          = nil
			@default_type = :error
			@buffer       = ""
			reopen(out)
		end
		
		def process(obj)
			@out.puts(obj.serialize)
			@out.flush
		end
		
		def reopen(out)
			close
			@out = out.respond_to?(:to_str) ? ::File.open(out, "a") : out
			raise TypeError, "out #{@out} does not respond to 'puts'." unless @out.respond_to?(:puts)
			self
		end

		def close
			@out.close if @out.respond_to?(:close)
			self
		end
		
		def closed?
			@out.respond_to?(:close) ? @out.closed? : true
		end
	end
end