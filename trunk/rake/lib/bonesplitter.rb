require 'stringio'



module BoneSplitter
	@libs = {}

	class <<BoneSplitter
		attr_accessor :libs
	end

	def version_proc(constant)
		proc {
			file    = constant.gsub(/::/, '/').downcase
			names   = constant.split(/::/)
			require(file)
			version = names.inject(Object) { |nesting, name| nesting.const_get(name) }
		}
	end
	
	def detect_libs(libs)
		libs.each { |lib|
			begin
				silenced do
					require lib
				end
				BoneSplitter.libs[lib.gsub(/\//, '_').to_sym] = true
			rescue LoadError
			end
		}
	end
	
	def quietly
		verbose, $VERBOSE = $VERBOSE, nil
		yield
	ensure
		$VERBOSE = verbose
	end
	
	def silenced
		a,b     = $stderr, $stdout
		$stderr = StringIO.new
		$stdout = StringIO.new
		yield
	ensure
		$stderr, $stdout = a,b
	end
	
	def lib?(name)
		BoneSplitter.libs[name.to_sym]
	end
end
