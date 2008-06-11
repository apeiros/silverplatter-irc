#--
# Copyright 2007 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'log/entry'



# == Description
# log/entry.rb provides some convenience methods in Log.
#
# == Synopsis
# log("Some info")
# log("Danger!", :warn)
# warn("Danger!")
# debug("mecode was here")
#
module Log
	module Comfort
		# where data is logged to
		attr_accessor :logger
		
		# Used for the origin-field in the log
		alias log_origin class

		# See Log::Message.new
		# Module::log(*args) is simply: $stderr.puts(Log::Message.new(*args))
		def log(text, severity=:info, origin=nil, data=nil, *flags)
			(@logger || $stderr).puts(
				Log::Entry.new(text.to_str, severity, origin||log_origin, data=nil, *flags)
			)
		end
	
		# See Log::Entry.new to see what arguments are valid.
		# Module::debug(text, *args) is the same as:
		#   $stderr.puts(Log::Message.new(text, :debug, *args))
		def debug(text, origin=nil, data=nil, *flags)
			(@logger || $stderr).puts(
				Log::Entry.new(text.to_str, :debug, origin||log_origin, data=nil, *flags)
			)
		end

		# See Log::Entry.new to see what arguments are valid.
		# Module::info(text, *args) is the same as:
		#   $stderr.puts(Log::Message.new(text, :info, *args))
		def info(text, origin=nil, data=nil, *flags)
			(@logger || $stderr).puts(
				Log::Entry.new(text.to_str, :info, origin||log_origin, data=nil, *flags)
			)
		end
	
		# See Log::Entry.new to see what arguments are valid.
		# Module::warn(text, *args) is the same as:
		#   $stderr.puts(Log::Message.new(text, :warn, *args))
		def warn(text, origin=nil, data=nil, *flags)
			(@logger || $stderr).puts(
				Log::Entry.new(text.to_str, :warn, origin||log_origin, data=nil, *flags)
			)
		end
	
		# See Log::Entry.new to see what arguments are valid.
		# Module::error(text, *args) is the same as:
		#   $stderr.puts(Log::Message.new(text, :error, *args))
		def error(text, origin=nil, data=nil, *flags)
			(@logger || $stderr).puts(
				Log::Entry.new(text.to_str, :error, origin||log_origin, data=nil, *flags)
			)
		end
	
		# See Log::Entry.new to see what arguments are valid.
		# Module::fail(text, *args) is the same as:
		#   $stderr.puts(Log::Message.new(text, :fail, *args))
		def fail(text, origin=nil, data=nil, *flags)
			(@logger || $stderr).puts(
				Log::Entry.new(text.to_str, :fail, origin||log_origin, data=nil, *flags)
			)
		end

		# Exception is special cased, if @logger || $stderr responds to 'exception',
		# the exception is just forwarded, else it uses puts and prints
		# the exception and the backtrace
		def exception(e)
			log = @logger || $stderr
			if log.respond_to?(:exception) then
				log.exception(e)
			else
				log.puts("#{Time.now.strftime('%FT%T')} [exception]: #{e} (#{e.class})")
				if $VERBOSE then
					prefix = "--> "
					log.puts(*e.backtrace.map { |l| prefix+l })
				end
			end
		end
	end

	# enable Log.log etc.
	extend Comfort
end
