namespace :loc do
  desc 'Assess the number of code and comment lines'
  optional_task :assess, 'AssessCode' do
  	task :assess do
			a = AssessCode.new(
				'.',
				'lib/**/*.rb',
				'bin/**/*',
				'data/**/*.rb'
			)
			puts "Code"
			a.put_assessment
			
			a = AssessCode.new(
				'.',
				'spec/**/*.rb',
				'test/**/*.rb'
			)
			puts "\nTests"
			a.put_assessment
		end
	end
end  # namespace :loc

desc 'Alias to loc:assess'
task :loc => 'loc:assess'
