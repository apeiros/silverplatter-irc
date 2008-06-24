# This rakefile doesn't define any tasks, it is run after Rakefile has run and before
# any other rakefile is imported, so it can clean up the Project object and resolve some
# dependencies.


# defaultize gem task
if Project.gem then
	Project.gem.executables   ||= []
	Project.gem.package_files ||= []
end
