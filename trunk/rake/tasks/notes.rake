namespace :notes do
	desc "Enumerate all annotations"
	task :show do |t|
		regex = /^.*(?:#{Project.notes.tags.map { |e| Regexp.escape(e) }.join('|')}).*$/
		Project.notes.include.each { |glob|
			Dir.glob(glob) { |file|
				data   = File.read(file)
				header = false
				data.scan(regex) {
					unless header then
						puts "#{file}:"
						header = true
					end
					printf "- %4d: %s\n", $`.count("\n")+1, $&.strip
				}
			}
		}
	end
end # namespace :notes

task :notes => 'notes:show'
