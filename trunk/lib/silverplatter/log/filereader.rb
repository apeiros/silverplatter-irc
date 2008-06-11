module Log
	class FileReader
		include Enumerable
		class Filter
			module Grep;         def =~(entry); entry.text =~ @arg1;             end; end
			module NoGrep;       def =~(entry); entry.text !~ @arg1;             end; end
			module Find;         def =~(entry); entry.text.include?(@arg1);      end; end
			module NoFind;       def =~(entry); !entry.text.include?(@arg1);     end; end
			module StartDate;    def =~(entry); entry.time > @arg1;              end; end
			module EndDate;      def =~(entry); entry.time < @arg1;              end; end
			module OneOfLevels;  def =~(entry); @arg1.include?(entry.severity);  end; end
			module NoneOfLevels; def =~(entry); !@arg1.include?(entry.severity); end; end

			Types = {
				:grep           => Grep,
				:no_grep        => NoGrep,
				:find           => Find,
				:no_find        => NoFind,
				:start_date     => StartDate,
				:end_date       => EndDate,
				:one_of_levels  => OneOfLevels,
				:none_of_levels => NoneOfLevels,
			}

			def initialize(type, *args)
				extend Types[type]
				@arg1 = args.first
				@args = args
			end
		end

		def initialize(file)
			@file    = ::File.open(file, "r")
			@pos     = 0
			@cache   = {}
			@filters = []
		end
		
		def add_filter(type, *args)
			@filters << Filter.new(type, *args)
		end
		
		def matches(entry)
			@filters.all? { |filter| filter =~ entry }
		end		
		
		def head(n)
			i = 0
			while line = @file.gets and i < n
				entry = Log::Entry.deserialize(line)
				if matches(entry) then
					yield(entry)
					i+=1
				end
			end
			entries
		end

		def tail(n, &block)
			entries = []
			while line = @file.gets and entries.length < n
				entry = Log::Entry.deserialize(line)
				entries.push entry if matches(entry)
			end
			while line = @file.gets
				entry = Log::Entry.deserialize(line)
				entries.push entry if matches(entry)
				entries.shift
			end
			entries.compact
			entries.each(&block)
		end
		
		def each
			while line = @file.gets
				entry = Log::Entry.deserialize(line)
				yield(entry) if matches(entry)
			end
		end
	end
end