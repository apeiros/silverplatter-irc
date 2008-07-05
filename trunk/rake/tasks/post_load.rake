#--
# Copyright 2007-2008 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



# This rakefile doesn't define any tasks, it is run after Rakefile has run and before
# any other rakefile is imported, so it can clean up the Project object and resolve some
# dependencies.


# defaultize meta data, have to do this here because it's needed by gem.rake before any task is run.
Project.meta.summary     ||= proc { extract_summary() }
Project.meta.description ||= proc { extract_description() || extract_summary() }
Project.meta.__finalize__
