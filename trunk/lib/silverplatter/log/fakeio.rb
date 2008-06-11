#--
# Copyright 2007 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module Log

	# == Description
	# Fakes most IO methods and forwards the converted data to #process
	#
	# == Requisites
	# * @buffer initialized to ""
	# * #process method present (this should write to the storage)
	# * #convert method present (see Log::Converter)
	#
	# == Notes
	# Following methods might be useful to be implemented:
	#   binmode, fcntl, fileno, flush, fsync, isatty, lineno, lineno=, pid, pos,
	#   pos=, , scanf, seek, soak_up_spaces, stat, sync, sync=, sysread, tell, to_i,
	#   to_io, tty?
	#
	# Following write methods are NOT implemented:
	#   puts, syswrite, write_nonblock
	#
	# All read methods must be implemented by the including class
	#     
	module FakeIO
		def process_buffer
			while line = @buffer.slice!(/.*?\n/)
				process(convert(line))
			end
		end

		def <<(obj)
			process(convert(obj))
		end

		def puts(*objs)
			objs.each { |obj| process(convert(obj)) }
		end

		def write(*objs)
			@buffer << objs.join("")
			process_buffer
		end
		alias print write

		def printf(*args)
			@buffer << sprintf(*args)
			process_buffer
		end
	end
end
