# $Id$

if HAVE_SPEC_RAKE_SPECTASK

namespace :spec do

  desc 'Run all specs with basic output'
  Spec::Rake::SpecTask.new(:run) do |t|
  	p t, t.method(:spec_opts=)
    t.spec_opts = [] #PROJ.spec.opts
    t.spec_files = PROJ.spec.files
    t.libs += PROJ.ext.libs
  end

  desc 'Run all specs with text output'
  Spec::Rake::SpecTask.new(:specdoc) do |t|
    t.spec_opts = PROJ.spec.opts + ['--format', 'specdoc']
    t.spec_files = PROJ.spec.files
    t.libs += PROJ.ext.libs
  end

  if HAVE_RCOV
    desc 'Run all specs with RCov'
    Spec::Rake::SpecTask.new(:rcov) do |t|
      t.spec_opts = PROJ.spec.opts
      t.spec_files = PROJ.spec.files
      t.libs += PROJ.ext.libs
      t.rcov = true
      t.rcov_opts = PROJ.rcov.opts + ['--exclude', 'spec']
    end
  end

end  # namespace :spec

desc 'Alias to spec:run'
task :spec => 'spec:run'

task :clobber => 'spec:clobber_rcov' if HAVE_RCOV

remove_desc_for_task %w(spec:clobber_rcov)

end  # if HAVE_SPEC_RAKE_SPECTASK

# EOF
