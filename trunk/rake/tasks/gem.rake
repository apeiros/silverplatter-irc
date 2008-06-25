require 'rake/gempackagetask'

namespace :gem do
	Project.gem.spec = Gem::Specification.new do |s|
		s.name                  = Project.gem.name
		s.version               = Project.gem.version
		s.summary               = Project.gem.summary
		s.authors               = Project.gem.authors
		s.email                 = Project.gem.email
		s.homepage              = Project.gem.homepage
		s.rubyforge_project     = Project.gem.rubyforge_project
		s.description           = Project.gem.description
		s.required_ruby_version = Project.gem.required_ruby_version if Project.gem.required_ruby_version

		Project.gem.dependencies.each do |dep|
			s.add_dependency(*dep)
		end

		s.files            = Project.gem.files
		s.executables      = Project.gem.executables.map {|fn| File.basename(fn)}
		s.extensions       = Project.gem.extensions

		s.bindir           = Project.gem.bin_dir
		s.require_paths    = Project.gem.require_paths if Project.gem.require_paths

		s.rdoc_options     = Project.gem.rdoc_options
		s.extra_rdoc_files = Project.gem.extra_rdoc_files
		s.has_rdoc         = Project.gem.has_rdoc

		if Project.gem.test_file then
			s.test_file  = Project.gem.test_file
		elsif Project.gem.test_files
			s.test_files = Project.gem.test_files
		end

		# Do any extra stuff the user wants
		Project.gem.extras.each do |msg, val|
			case val
				when Proc
					val.call(s.send(msg))
				else
					s.send "#{msg}=", val
			end
		end
	end # Gem::Specification.new

	# A prerequisites task that all other tasks depend upon
	task :prerequisites

	desc 'Show information about the gem'
	task :debug => 'gem:prerequisites' do
		puts Project.gem.spec.to_ruby
	end

	pkg = Rake::PackageTask.new(Project.gem.name, Project.gem.version) do |pkg|
		pkg.need_tar      = Project.gem.need_tar
		pkg.need_zip      = Project.gem.need_zip
		pkg.package_files = Project.gem.package_files if Project.gem.package_files
	end
	#Rake::Task['gem:package'].instance_variable_set(:@full_comment, nil)

	desc "Build the gem file #{Project.gem.gem_file}"
	task :package => %W[gem:prereqs #{pkg.package_dir}/#{Project.gem.gem_file}]

	file "#{pkg.package_dir}/#{Project.gem.gem_file}" => [pkg.package_dir, *Project.gem.files] do
		when_writing("Creating GEM") {
			Gem::Builder.new(Project.gem.spec).build
			verbose(true) {
				mv gem_file, "#{pkg.package_dir}/#{gem_file}"
			}
		}
	end

	desc 'Install the gem'
	task :install => [:clobber, 'gem:package'] do
		sh "#{SUDO} #{GEM} install --no-update-sources pkg/#{Project.gem.spec.full_name}"
	end

	desc 'Uninstall the gem'
	task :uninstall do
		if installed_list = Gem.source_index.find_name(Project.gem.name) then
			installed_versions = installed_list.map { |s| s.version.to_s }
			if installed_versions.include?(Project.gem.version) then
				sh "#{SUDO} #{GEM} uninstall --version '#{Project.gem.version}' --ignore-dependencies --executables #{Project.gem.name}"
			end
		end
	end

	desc 'Reinstall the gem'
	task :reinstall => [:uninstall, :install]

	desc 'Cleanup the gem'
	task :cleanup do
		bin.gem "#{bin.sudo} #{bin.gem} cleanup #{Project.gem.spec_name}"
	end

end  # namespace :gem

desc 'Alias to gem:package'
task :gem     => 'gem:package'
task :clobber => 'gem:clobber'

