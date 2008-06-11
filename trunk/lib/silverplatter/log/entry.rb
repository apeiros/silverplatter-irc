#--
# Copyright 2007 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'enumerator'
require 'log'



module Log
	# currently unused
	Printable  = "%d#{RecordSeparator}%s#{RecordSeparator}%s#{RecordSeparator}%s"
	# currently *only* used by Entry#serialize, but not by Entry::deserialize
	Serialized =
		"%d#{RecordSeparator}" \
		"%s#{RecordSeparator}" \
		"%s#{RecordSeparator}" \
		"%s#{RecordSeparator}" \
		"%s#{RecordSeparator}" \
		"%s"

	class Entry
		# the value used by #to_s if no format is given
		DefaultFormat = "%{time:%FT%T} [%{severity}]: %{text} in %{origin}"

		class <<self
			attr_accessor :time_format
			
			def deserialize(line)
				time, severity, origin, text, flagstr, data = line.chomp(RecordTerminator).split(RecordSeparator)
				flags = {}
				flagstr.split(UnitSeparator).each_cons(2) { |key, value|
					flagstr[key] = value
				}
				severity = Integer(severity) rescue severity
				new(
					text,
					InvSeverity[severity],
					Log.unescape(origin),
					Marshal.load(Log.unescape(data)),
					Time.at(time.to_i),
					flags
				)
			end

			def formatter_for(entity, &formatter)
				@formatter[entity] = formatter
			end
			
			def format(entity, value, *args)
				@formatter[entity].call(value, *args)
			end

			def format_time(entry, time, format=nil)
				entry.time.strftime(format || @time_format)
			end

			def format_origin(entry)
				entry.origin.to_s
			end

			def format_severity(entry)
				entry.severity.to_s
			end
			
			def format_flags(entry, flags)
				entry.flags.map{ |k,v| "#{k}: #{v}"}.join(", ")
			end
			
			def format_text(entry)
				entry.text.chomp.gsub(/[\r\n]+/, '; ').gsub(/[\x00-\x1f\x7f]/, '.')
			end
		end

		Severity = Hash.new{|h,k|k}.merge({
			:debug => 1,
			:info  => 2,
			:warn  => 4,
			:error => 8,
			:fail  => 16,
		})
		InvSeverity = Severity.invert
		@formatter = {
			"time"     => method(:format_time),
			"severity" => method(:format_severity),
			"origin"   => method(:format_origin),
			"flags"    => method(:format_flags),
			"text"     => method(:format_text), #Log.method(:escape),
		}
		@time_format = "%FT%T"
		
		attr_reader :time
		attr_reader :severity
		attr_reader :origin
		attr_reader :text
		attr_reader :flags
		attr_reader :data
		def initialize(text, severity=:info, origin=nil, data=nil, *flags)
			@time     = flags.first.kind_of?(Time) ? flags.shift : Time.now
			@severity = severity
			@origin   = origin.to_s
			@text     = text
			@data     = data
			@flags    = flags.last.kind_of?(Hash) ? flags.pop : {}
			@flags.each_key { |k,v| @flags[k.to_s] = @flags.delete(k) }
			flags.each { |flag| @flags[flag.to_s] = true }
		end
		
		def [](key)
			@flags[key]
		end
		
		def debug?
			@severity == Severity[:debug]
		end

		def info?
			@severity == Severity[:info]
		end

		def warn?
			@severity == Severity[:warn]
		end

		def error?
			@severity == Severity[:error]
		end

		def fail?
			@severity == Severity[:fail]
		end

		def serialize
			Serialized %  [
				@time,
				Severity[@severity],
				Log.escape(@origin),
				Log.escape(@text),
				@flags.map.join(UnitSeparator),
				Log.escape(Marshal.dump(@data))
			]
		end
	
		def to_s(format=nil)
			format ||= DefaultFormat
			format.gsub(/%(%|\{[^}]+\})/) { |match|
				if match == "%%" then
					"%"
				else
					entity, *args = match[2..-2].split(/:/)
					Entry.format(entity, self, *args)
				end
			}
		end
		
		def inspect
			"#<%s %s %s %s %s flags=%s data=%s>" %  [
				self.class,
				@time.strftime("%FT%T"),
				@severity,
				@origin,
				@text.inspect,
				@flags.inspect,
				@data.inspect
			]
		end
	end
end
