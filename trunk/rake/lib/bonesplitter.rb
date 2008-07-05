require 'stringio'



class Array
	include Comparable
end

module BoneSplitter
	@libs = {}

	class <<BoneSplitter
		attr_accessor :libs
	end
	
	private
	def optional_task(name, depends_on_constant)
		# puts "#{name} requires #{depends_on_constant}: #{!!deep_const(depends_on_constant)}"
		if deep_const(depends_on_constant) then
			yield
		else
			task name do
				"You're missing a dependency to run this thread (#{depends_on_constant})"
			end
		end
	end
	
	def deep_const(name)
		name.split(/::/).inject(Object) { |nesting, name|
			return nil unless nesting.const_defined?(name)
			nesting.const_get(name)
		}
	end

	def version_proc(constant)
		proc {
			file    = constant.gsub(/::/, '/').downcase
			require(file)
			version = deep_const(constant)
			version && version.to_s
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
	
	# same as lib? but aborts if a dependency isn't met
	def dependency(names, warn_message=nil)
		abort unless lib?(names, warn_message)
	end
	alias dependencies dependency
	
	def lib?(names, warn_message=nil)
		Array(names).map { |name|
			next true if BoneSplitter.libs[name] # already been required earlier
			begin
				silenced do
					require name
				end
				BoneSplitter.libs[name] = true
				true
			rescue LoadError
				warn(warn_message % name) if warn_message
				false
			end
		}.all? # map first so we get all messages at once
	end
	
	def manifest(mani=Project.meta.manifest)
		File.read(mani).split(/\n/)
	end
	
	def manifest_candidates
		cands = Dir['**/*']
		if Project.manifest.ignore then
			Project.manifest.ignore.map { |glob| cands -= Dir[glob] }
		end
		cands - Dir['**/*/'].map { |e| e.chop }
	end

	def has_version?(having_version, minimal_version, maximal_version=nil)
		a = having_version.split(/\./).map { |e| e.to_i }
		b = minimal_version.split(/\./).map { |e| e.to_i }
		c = maximal_version && maximal_version.split(/\./).map { |e| e.to_i }
		c ? a.between?(b,c) : a >= b
	end

	# requires that 'readme' is a file in markdown format and that Markdown exists
	def extract_summary(file=Project.meta.readme)
		return nil unless File.readable?(file)
		return "" unless lib?(%w[hpricot markdown], "Requires %s to extract the summary")
		(Hpricot(Markdown.new(File.read(file)).to_html)/"h2[text()=Summary]").first.next_sibling.inner_text
	rescue => e
		warn "Failed extracting the summary: #{e}"
		nil
	end
	
	# requires that 'readme' is a file in markdown format and that Markdown exists
	def extract_description(file=Project.meta.readme)
		return nil unless File.readable?(file)
		return "" unless lib?(%w[hpricot markdown], "Requires %s to extract the description")
		(Hpricot(Markdown.new(File.read(file)).to_html)/"h2[text()=Description]").first.next_sibling.inner_text
	rescue => e
		warn "Failed extracting the description: #{e}"
		nil
	end
end
