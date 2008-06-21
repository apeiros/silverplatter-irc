namespace :spec do
	desc 'Run all specs with basic output'
	task :run do |t|
		puts "bacon..."
		Bacon.extend Bacon.const_get('TestUnitOutput') rescue abort "No such formatter: #{output}"
		Bacon.summary_on_exit
		Dir.glob('spec/**/*_spec.rb') { |file|
		  load file
		}
	end
	
	desc 'Run all specs with text output'
	task :doc do |t|
	end
	
	if lib?(:rcov) then
		desc 'Run all specs with Rcov'
		task :rcov do |t|
			t.ruby_opts = PROJ.ruby_opts
			t.spec_opts = PROJ.spec.opts
			t.spec_files = PROJ.spec.files
			t.libs += PROJ.libs
			t.rcov = true
			t.rcov_dir = PROJ.rcov.dir
			t.rcov_opts = PROJ.rcov.opts + ['--exclude', 'spec']
		end
	
		#Rcov::VerifyTask.new(:verify) do |t| 
		#	t.threshold               = Project.rcov.threshold
		#	t.index_html              = File.join(Project.rcov.dir, 'index.html')
		#	t.require_exact_threshold = Project.rcov.threshold_exact
		#end
	
		#task :verify => :rcov
		#remove_desc_for_task %w(spec:clobber_rcov)
	end
end  # namespace :spec

desc 'Alias to spec:run'
task :spec => 'spec:run'

task :clobber => 'spec:clobber'
