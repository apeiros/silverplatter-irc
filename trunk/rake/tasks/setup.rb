# $Id$

$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__)+'/lib'))

require 'rubygems'
require 'rake'
require 'fileutils'
require 'project'
require 'bonesplitter'

PROJ = Project.new # just a blank-slated openstruct

PROJ.ext       = OpenStruct.new # extension options
PROJ.gem       = OpenStruct.new # gem information
PROJ.nanoc     = OpenStruct.new # settings for nanoc (web tasks)
PROJ.rcov      = OpenStruct.new # settings for rcov tasks
PROJ.rdoc      = OpenStruct.new # settings for rdoc tasks
PROJ.rf        = OpenStruct.new # settings for rubyforge tasks
PROJ.spec      = OpenStruct.new # settings for spec tasks
PROJ.svn       = OpenStruct.new # settings for svn tasks
PROJ.test      = OpenStruct.new # settings for test tasks
PROJ.use       = OpenStruct.new # 
PROJ.web       = OpenStruct.new # settings for web tasks


# Project
PROJ.name            = nil
PROJ.summary         = nil
PROJ.description     = nil
PROJ.changes         = nil
PROJ.authors         = ['Stefan Rusterholz']
PROJ.email           = ['apeiros@gmx.net']
PROJ.url             = nil
PROJ.version         = ENV['VERSION'] || '0.0.1'
PROJ.exclude         = %w(tmp$ bak$ ~$ CVS .svn/ ^pkg/ ^doc/)
PROJ.files           = File.exist?('Manifest.txt') ? manifest_files('Manifest.txt') : []


# Rubyforge
PROJ.rf.user         = 'rstefan'
PROJ.rf.name         = nil
PROJ.rf.webroot      = nil


# Rdoc
PROJ.rdoc.opts       = %w[
                         --inline-source
                         --line-numbers
                         --charset utf-8
                         --tab-width 2
                       ]
PROJ.rdoc.include    = %w(^lib/ ^bin/ ^ext/ .txt$)
PROJ.rdoc.exclude    = %w(extconf.rb$ ^Manifest.txt$)
PROJ.rdoc.main       = 'README.txt'
PROJ.rdoc.dir        = '../online/docs'
PROJ.rdoc.remote_dir = nil
PROJ.rdoc.template   = Gem.searcher.find("allison").full_gem_path+"/lib/allison" if HAVE_ALLISON


# Rspec / Beacon
PROJ.spec.files      = FileList['spec/**/*_spec.rb']
PROJ.spec.opts       = []


# Test::Unit
PROJ.test.files      = FileList['test/**/test_*.rb']
PROJ.test.file       = 'test/all.rb'
PROJ.test.opts       = []


# Rcov
PROJ.rcov.opts       = ['--sort', 'coverage', '-T']


# Extensions
PROJ.ext.files = FileList['ext/**/extconf.rb']
PROJ.ext.ruby_opts   = %w(-w)
PROJ.ext.libs        = %w(lib ext).select {|dir| test ?d, dir }


# Gem Packaging
PROJ.gem.executables  = PROJ.files.find_all {|fn| fn =~ %r/^bin/}
PROJ.gem.dependencies = []
PROJ.gem.need_tar     = true
PROJ.gem.need_zip     = false


# Website
PROJ.web.local_dir        = "web"
PROJ.web.remote_dir       = nil
PROJ.web.host             = nil
PROJ.web.validation_cache = nil
PROJ.web.compiler         = "nanoc"
PROJ.nanoc.command        = "compile"
#PROJ.nanoc.


# File Annotations
PROJ.annotation_exclude    = []
PROJ.annotation_extensions = %w(.txt .rb .erb) << ''


# Subversion Repository
PROJ.use.svn      = false
PROJ.svn.root     = nil
PROJ.svn.trunk    = 'trunk'
PROJ.svn.tags     = 'tags'
PROJ.svn.branches = 'branches'


# Load the other rake files in the tasks folder
rakefiles = Dir.glob('tasks/*.rake').sort
rakefiles.unshift(rakefiles.delete('tasks/post_load.rake')).compact!
import(*rakefiles)

