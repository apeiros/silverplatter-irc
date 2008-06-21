$LOAD_PATH.unshift(File.expand_path("#{__FILE__}/../lib"))

begin; require 'rubygems'; rescue LoadError; end
require 'projectclass'
require 'bonesplitter'

include BoneSplitter
detect_libs %w[
	allison
	bacon
	rcov
]
Project = ProjectClass.new

# Gem Packaging
Project.gem = ProjectClass.new({
	:dependencies => %w[silverplatter-log],
	:executables  => nil,
	:extensions   => FileList['ext/**/extconf.rb'],
	:files        => nil,
	:need_tar     => true,
	:need_zip     => false,
	:extras       => {},
})

# Data about the project itself
Project.meta = ProjectClass.new({
	:name             => nil,
	:version          => nil,
	:author           => "Stefan Rusterholz",
	:contact          => "apeiros@gmx.net",
	:website          => nil,
	:bugtracker       => nil,
	:feature_requests => nil,
	:irc              => "irc://freenode.org/#silverplatter",
	:release_notes    => "NEWS.markdown",
	:changelog        => "CHANGELOG.markdown",
	:todo             => "TODO.markdown",
	:readme           => "README.markdown",
	:gem_host         => :rubyforge,
	:configurations   => "~/Library/Application Support/Bonesplitter",
})

# File Annotations
Project.notes = ProjectClass.new({
	:include    => %w[trunk/lib/**/*.rb, trunk/{bin,ext}/**/*],
	:exclude    => %w[],
	:tags       => %w[FIXME OPTIMIZE TODO],
})

# Rcov
Project.rcov = ProjectClass.new({
	:dir             => 'coverage',
	:opts            => %w[--sort coverage -T],
	:threshold       => 100.0,
	:threshold_exact => false,
})

# Rdoc
Project.rdoc = ProjectClass.new({
	:opts       => %w[
                   --inline-source
                   --line-numbers
                   --charset utf-8
                   --tab-width 2
                 ],
	:include    => %w[^lib/ ^bin/ ^ext/ \.txt$],
	:exclude    => %w[extconf.rb$ ^Manifest.txt$],
	:main       => 'README.markdown',
	:dir        => 'docs',
	:remote_dir => 'irc/docs',
	:template   => lib?(:allison) && Gem.searcher.find("allison").full_gem_path+"/lib/allison",
})

# Rubyforge
Project.rubyforge = ProjectClass.new({
	:project    => nil, # The rubyforge projectname
})

# Specs (bacon)
Project.rubyforge = ProjectClass.new({
	:files => FileList['spec/**/*_spec.rb'],
	:opts  => []
})

# Load the other rake files in the tasks folder
rakefiles = Dir.glob('rake/tasks/*.rake').sort
rakefiles.unshift(rakefiles.delete('rake/tasks/post_load.rake')).compact!
import(*rakefiles)
