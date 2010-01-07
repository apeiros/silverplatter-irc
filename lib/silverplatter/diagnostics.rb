#--
# Copyright 2007 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



# Used to provide better diagnostics
class Diagnostics
	def initialize(owner, exceptions={})
		@owner      = owner
		@exceptions = Hash.new { |h,k| [NoMethodError, "undefined method `#{k}' for #{@owner.inspect}"] }.merge(exceptions)
	end

	def method_missing(m, *args, &block)
		ex, msg = *@exceptions[m]
		raise ex, msg
	end
end