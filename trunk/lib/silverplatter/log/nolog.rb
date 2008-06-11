#--
# Copyright 2007 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module Log
	# discards all messages
	class NoLog
		def respond_to?(m,*a)
			true
		end
		def method_missing(*a)
		end
	end
end