#--
# Copyright 2007 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



# == Synopsis
#   Logfile = Log::File.new("foo.log")
#   $stderr = Log::Forward(Logfile, :warn) # capture everything that prints to $stderr and treat it as :warn level message
#   $stdout = Log::Forward(Logfile, :info)
#   $stderr.puts "foo" # same as Log::File#log("foo", :warn)
#   $stdout.puts "bar" # same as Log::File#log("bar", :info)
#   begin
#     raise "baz"
#   rescue => exception
#     $stdout.puts(exception) # same as Log::File#log(exception)
#   end
#
# == Use-cases
# === Daemon
# Since a daemon should not output anything at all, the advice is to create a
# logger (Log::File e.g.) and assign a Log::Forward to each, $stdout and $stderr.
# It's suggested to use :info as the default level for $stdout and :warn for
# $stderr.
#
# === Application
# If you use Log with your application, you most likely want to log to a file.
# The advice for that is to simply assign a Log::File to $stderr, anything that
# prints to $stderr is now logged as :warn.
#
# === Library
# With a library you most likely just want Log::Comfort. It adds logging methods
# and convenience methods to your class. It uses @logger if set, else $stderr to
# puts a Log::Entry. That way your library has decent logging even if the
# employing app doesn't use a logger.
#
# == Notes
# require 'log/kernel' to get convenience methods in Kernel
# it isn't required via 'log' alone to avoid accidental method name clashes.
# notice that log/kernel will override Kernel#warn
#
module Log
	GroupSeparator   = "\x1d"
	RecordSeparator  = "\x1e"
	UnitSeparator    = "\x1f"
	RecordTerminator = "\n"

	# escape binary data, the data will contain no \n, \r or \t's after escaping, but
	# still contain binary characters, but all of them preceeded by \e
	def self.escape(data)
		data.
			gsub(/\e/, "\e\e").
			gsub(/\n/, "\en").
			gsub(/\r/, "\er").
			gsub(/\t/, "\et").
			gsub(/[\x00-\x1a\x1c-\x1f]/, "\e\\0")
	end
	
	# unescapes data escaped by Log.escape
	def self.unescape(data)
		data.
			gsub(/\en/, "\n").
			gsub(/\er/, "\r").
			gsub(/\et/, "\t").
			gsub(/\e(.)/, '\1')
	end
end



require 'silverplatter/log/comfort'
require 'silverplatter/log/converter'
require 'silverplatter/log/entry'
require 'silverplatter/log/forward'
require 'silverplatter/log/fakeio'
require 'silverplatter/log/file'
require 'silverplatter/log/nolog'



if __FILE__ == $0 then
	begin
		require 'stringio'
		lf = StringIO.new
		log = Log::File.new(lf)
		$stderr = Log::Forward.new(log, :warn)
		warn "foo"
		p Log::Entry.deserialize(lf.string.split("\n").first)
		puts "end"
	rescue => e
		puts e, *e.backtrace
	end
end