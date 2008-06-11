namespace :web do
	desc 'Generate website files'
	task :generate => :docs do
		cd "web" do
			system(PROJ.web.compiler, *PROJ.web.compile_opts)
		end
	end
	
	desc 'Validate website'
	task :validate => :generate do
		require 'web/lib/w3validator'
		validator = W3Validator.new(PROJ.web.local_dir+"/*.html")
		validates = validator.validate_changed(PROJ.web.validation_cache) { |file, valid|
			puts "Invalid: #{file}" unless valid
		}
		raise "Website did not validate, aborting task" unless validates
		validator.cache(PROJ.web.validation_cache)
	end
	
	desc 'Create docs for the website'
	task :docs => 'doc:rdoc'
	
	desc 'Upload website files to rubyforge'
	task :upload do
		sh %{rsync -aCv #{PROJ.web.local_dir}/ #{PROJ.web.host}:#{PROJ.web.remote_dir}}
	end
	
	desc 'Generate and upload website files'
	task :all => [:generate, :upload]
end # namespace :website

desc 'Alias web to web:all'
task :web => 'web:all'
