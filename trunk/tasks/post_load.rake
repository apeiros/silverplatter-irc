p :post_load
# $Id$

# This file does not define any rake tasks. It is used to load some project
# settings if they are not defined by the user.

unless PROJ.changes
  PROJ.changes = paragraphs_of('History.txt', 0..1).join("\n\n")
end

unless PROJ.description
  PROJ.description = paragraphs_of('README.txt', 'description').join("\n\n")
end

unless PROJ.summary
  PROJ.summary = PROJ.description.split('.').first
end

# Web
#		host       = "#{PROJ.rubyforge_user}@rubyforge.org"
#		remote_dir = "/var/www/gforge-projects/#{PROJ.rubyforge_path}/"
#		local_dir  = '../online'



# EOF
