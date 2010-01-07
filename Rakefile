# Look in the tasks/setup.rb file for the various options that can be
# configured in this Rakefile. The .rake files in the tasks directory
# are where the options are used.

require 'rake/initialize'

task :default => 'spec:run'



# Project details (defaults are in rake/initialize, some cleanup is done per section in the
# prerequisite task in each .task file, some other cleanup is done in post_load.rake)
Project.gem.dependencies      = %w[silverplatter-log]

Project.meta.name             = 'silverplatter-irc'
Project.meta.version          = version_proc("SilverPlatter::IRC::VERSION")
Project.meta.website          = 'http://silverplatter.rubyforge.org/irc'
Project.meta.bugtracker       = 'http://'
Project.meta.feature_requests = 'http://'
Project.meta.use_git          = true
Project.meta.readme           = 'README.rdoc'
Project.meta.summary          = extract_summary()
Project.meta.description      = extract_description()

Project.manifest.ignore       = %w[{docs,spec,stuff,test,web}/**/*]

Project.rubyforge.project     = 'silverplatter'
Project.rubyforge.path        = 'silverplatter/irc'
