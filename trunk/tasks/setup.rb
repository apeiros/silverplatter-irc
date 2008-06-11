# $Id$

require 'rubygems'
require 'rake'
require 'fileutils'
require 'ostruct'

PROJ = OpenStruct.new
class <<PROJ
	#p (private_instance_methods-%w(initialize undef_method)).sort
	#(private_instance_methods-%w(initialize undef_method)).each { |m| undef_method m }
	undef_method "gem"
end
PROJ.ext       = OpenStruct.new # extension options
PROJ.gem       = OpenStruct.new # gem information
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
PROJ.files =
  if test ?f, 'Manifest.txt'
    files = File.readlines('Manifest.txt').map {|fn| fn.chomp.strip}
    files.delete ''
    files
  else [] end


# Rubyforge
PROJ.rf.user         = 'rstefan'
PROJ.rf.name         = nil
PROJ.rf.webroot      = nil


# Rdoc
begin
	require 'allison' # nice rdoc templates
	PROJ.use.allison   = true
rescue LoadError
	PROJ.use.allison   = false
end
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
PROJ.rdoc.template   = Gem.searcher.find("allison").full_gem_path+"/lib/allison" if PROJ.use.allison


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
PROJ.web.host             = nil
PROJ.web.remote_dir       = nil
PROJ.web.local_dir        = nil
PROJ.web.validation_cache = nil
PROJ.web.compiler         = "nanoc"
PROJ.web.compile_opts     = []


# File Annotations
PROJ.annotation_exclude = []
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


# Setup some constants
WIN32 = %r/djgpp|(cyg|ms|bcc)win|mingw/ =~ RUBY_PLATFORM unless defined? WIN32

DEV_NULL = WIN32 ? 'NUL:' : '/dev/null'

def quiet( &block )
  io = [STDOUT.dup, STDERR.dup]
  STDOUT.reopen DEV_NULL
  STDERR.reopen DEV_NULL
  block.call
ensure
  STDOUT.reopen io.first
  STDERR.reopen io.last
end

DIFF = if WIN32 then 'diff.exe'
       else
         if quiet {system "gdiff", __FILE__, __FILE__} then 'gdiff'
         else 'diff' end
       end unless defined? DIFF

SUDO = if WIN32 then ''
       else
         if quiet {system 'which sudo'} then 'sudo'
         else '' end
       end

RCOV = WIN32 ? 'rcov.cmd'  : 'rcov'
GEM  = WIN32 ? 'gem.cmd'   : 'gem'

%w(rcov spec/rake/spectask rubyforge bones facets/ansicode).each do |lib|
  begin
    require lib
    Object.instance_eval {const_set "HAVE_#{lib.tr('/','_').upcase}", true}
  rescue LoadError
    Object.instance_eval {const_set "HAVE_#{lib.tr('/','_').upcase}", false}
  end
end

# Reads a file at +path+ and spits out an array of the +paragraphs+
# specified.
#
#    changes = paragraphs_of('History.txt', 0..1).join("\n\n")
#    summary, *description = paragraphs_of('README.txt', 3, 3..8)
#
def paragraphs_of( path, *paragraphs )
  title = String === paragraphs.first ? paragraphs.shift : nil
  ary = File.read(path).delete("\r").split(/\n\n+/)

  result = if title
    tmp, matching = [], false
    rgxp = %r/^=+\s*#{Regexp.escape(title)}/i
    paragraphs << (0..-1) if paragraphs.empty?

    ary.each do |val|
      if val =~ rgxp
        break if matching
        matching = true
        rgxp = %r/^=+/i
      elsif matching
        tmp << val
      end
    end
    tmp
  else ary end

  result.values_at(*paragraphs)
end

# Adds the given gem _name_ to the current project's dependency list. An
# optional gem _version_ can be given. If omitted, the newest gem version
# will be used.
#
def depend_on( name, version = nil )
  spec = Gem.source_index.find_name(name).last
  version = spec.version.to_s if version.nil? and !spec.nil?

  PROJ.dependencies << (version.nil? ? [name] : [name, ">= #{version}"])
end

# Adds the given arguments to the include path if they are not already there
#
def ensure_in_path( *args )
  args.each do |path|
    path = File.expand_path(path)
    $:.unshift(path) if test(?d, path) and not $:.include?(path)
  end
end

# Find a rake task using the task name and remove any description text. This
# will prevent the task from being displayed in the list of available tasks.
#
def remove_desc_for_task( names )
  Array(names).each do |task_name|
    task = Rake.application.tasks.find {|t| t.name == task_name}
    next if task.nil?
    task.instance_variable_set :@comment, nil
  end
end

# Change working directories to _dir_, call the _block_ of code, and then
# change back to the original working directory (the current directory when
# this method was called).
#
def in_directory( dir, &block )
  curdir = pwd
  begin
    cd dir
    return block.call
  ensure
    cd curdir
  end
end

# EOF
