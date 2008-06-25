require 'rake/rdoctask'

namespace :doc do
	Rake::RDocTask.new do |rd|
		rd.main       = Project.rdoc.main
		rd.rdoc_files = Project.rdoc.files
		rd.rdoc_dir   = Project.rdoc.output_dir
		rd.template   = Project.rdoc.template if Project.rdoc.template
		
		rd.options.concat(Project.rdoc.options)
	end

	desc 'Check documentation coverage with dcov'
	task :coverage do
		sh "find lib -name '*.rb' | xargs dcov"
	end

	desc 'Generate ri locally for testing'
 	task :ri => :clobber_ri do
		sh "#{RDOC} --ri -o ri ."
	end

	desc 'Remove ri products'
	task :clobber_ri do
		rm_r 'ri' rescue nil
	end
end

desc 'Alias to doc:rdoc'
task :doc => 'doc:rdoc'
