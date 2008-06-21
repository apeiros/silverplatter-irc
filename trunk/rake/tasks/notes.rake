namespace :notes do
	desc "Enumerate all annotations"
	task :show do |t|
		regex = /#{Project.notes.tags.map { |e| Regexp.escape(e) }.join('|')}/
		Project.notes.include.each { |glob|
			Dir.glob(glob) { |file|
				lines = File.readlines(file)
				(1..lines.size).zip(lines) { |nr, line|
					printf "%4d: %s", nr, line if line =~ regex
				}
			}
		}
	end
end # namespace :notes
