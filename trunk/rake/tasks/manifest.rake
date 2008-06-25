namespace :manifest do
	desc 'Verify the manifest'
	task :check do
		files   = manifest()
		cands   = manifest_candidates()
		missing = files-cands
		added   = cands-files

		puts added.sort.map { |f|
			"\e[32m+#{f}\e[0m"
		}
		puts missing.sort.map { |f|
			"\e[31m-#{f}\e[0m"
		}
	end

	desc 'Create a new manifest'
	task :create do
		files = manifest_files
		unless test(?f, PROJ.manifest_file)
			files << PROJ.manifest_file
			files.sort!
		end
		File.open(PROJ.manifest_file, 'w') {|fp| fp.puts files}
	end

	task :assert do
		files = manifest_files
		manifest = File.read(PROJ.manifest_file).split($/)
		raise "ERROR: #{PROJ.manifest_file} is out of date" unless files == manifest
	end

end  # namespace :manifest

desc 'Alias to manifest:check'
task :manifest => 'manifest:check'
