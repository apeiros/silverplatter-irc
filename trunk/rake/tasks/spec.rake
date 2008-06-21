if lib?(:spec_rake_verify_rcov) then
	require 'spec/rake/verify_rcov'
end

namespace :spec do
	task :prerequisite do
		begin
			require 'bacon'
		rescue LoadError
			abort('Missing bacon dependency to run task')
		end
	end

  desc 'Run all specs with basic output'
  task :run => :prerequisite do |t|
		Bacon.extend Bacon.const_get('TestUnitOutput') rescue abort "No such formatter: #{output}"
		Bacon.summary_on_exit
		
		Dir.glob("spec/**/*_spec.rb") { |file|
			load file
		}
  end

  desc 'Run all specs with text output'
  task :specdoc do |t|
    raise "Not implemented"
  end

  if lib?(:rcov) && lib?(:spec) then
    desc 'Run all specs with RCov'
    Spec::Rake::SpecTask.new(:rcov) do |t|
      t.ruby_opts = Project.ruby_opts
      t.spec_opts = Project.spec.opts
      t.spec_files = Project.spec.files
      t.libs += Project.libs
      t.rcov = true
      t.rcov_dir = Project.rcov.dir
      t.rcov_opts = Project.rcov.opts + ['--exclude', 'spec']
    end

    Rcov::VerifyTask.new(:verify) do |t| 
      t.threshold = Project.rcov.threshold
      t.index_html = File.join(Project.rcov.dir, 'index.html')
      t.require_exact_threshold = Project.rcov.threshold_exact
    end

    task :verify => :rcov
    remove_desc_for_task %w(spec:clobber_rcov)
  end

end  # namespace :spec

desc 'Alias to spec:run'
task :spec => 'spec:run'

task :clobber => 'spec:clobber'
