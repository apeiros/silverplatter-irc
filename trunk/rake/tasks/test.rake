import 'rake/tasks/spec.rake'

desc 'Test is done by spec'
task :test => 'spec:run'
