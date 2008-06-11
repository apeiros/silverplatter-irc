#--
# Copyright 2007 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module Log
	# Provides convenience mappings to #process
	# Map debug, info, warn, error, fail to log, log itself uses process with
	# Entry.new
	# See Log::File for an example.
	module Methods
		def log(*args)
			process(Entry.new(*args))
		end
		
		def debug(text, *args)
			log(text, :debug, *args)
		end

		def info(text, *args)
			log(text, :info, *args)
		end

		def warn(text, *args)
			log(text, :warn, *args)
		end

		def error(text, *args)
			log(text, :error, *args)
		end

		def fail(text, *args)
			log(text, :fail, *args)
		end
	end
end