# This rakefile doesn't define any tasks, it is run after Rakefile has run and before
# any other rakefile is imported, so it can clean up the Project object and resolve some
# dependencies.


# defaultize meta data
Project.meta.summary     ||= extract_summary()
Project.meta.description ||= extract_description()


# defaultize rdoc task
if Project.rdoc then
	Project.rdoc.files   ||= []
	Project.rdoc.files    += FileList.new(Project.rdoc.include || %w[lib/**/* *.{txt markdown rdoc}])
	Project.rdoc.files    -= FileList.new(Project.rdoc.exclude) if Project.rdoc.exclude
	Project.rdoc.files.reject! { |f| File.directory?(f) }
	Project.rdoc.title   ||= "#{Project.meta.name}-#{Project.meta.version} Documentation"
	Project.rdoc.options ||= []
	Project.rdoc.options.push('-t', Project.rdoc.title)
end

# defaultize gem task
if Project.gem then
	Project.gem.name                  ||= Project.meta.name
	Project.gem.version               ||= Project.meta.version
	Project.gem.summary               ||= Project.meta.summary
	Project.gem.description           ||= Project.meta.description
	Project.gem.authors               ||= Project.meta.authors || Array(Project.meta.author)
	Project.gem.email                 ||= Project.meta.email
	Project.gem.homepage              ||= Project.meta.website
	Project.gem.rubyforge_project     ||= (Project.rubyforge && Project.rubyforge.name) || Project.meta.name
	Project.gem.files                 ||= manifest()
	Project.gem.executables           ||= Array(Project.gem.executable)
	Project.gem.extensions            ||= Project.gem.files.grep %r/extconf\.rb$/
	Project.gem.bin_dir               ||= "bin"

	Project.gem.rdoc_options          ||= Project.rdoc && Project.rdoc.options
	Project.gem.extra_rdoc_files      ||= Project.rdoc && Project.rdoc.extra_files
	Project.gem.rdoc_options          ||= Project.rdoc && Project.rdoc.options
	
	# gem_file needs the generated gemspec and package object and is hence defaultized in gem.rake
end

Project.__hash__.each_value { |sub|
	sub.__hash__.each { |k,v|
		sub[k] = v.call if v.respond_to?(:call)
	}
}
