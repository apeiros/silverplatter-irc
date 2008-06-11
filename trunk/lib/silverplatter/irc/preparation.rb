#--
# Copyright 2007 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'silverplatter/diagnostics'
require 'silverplatter/log/comfort'
require 'socket'
require 'thread'



module SilverPlatter
	module IRC
		# Used by Connection#prepare
		class Preparation # :nodoc:
			def initialize(connection, block)
				@connection = connection
				@block      = block
			end
			
			# See Connection#wait_for
			# Adds the supplied proc object in the initialization as :prepare option.
			def wait_for(symbol, timeout=nil, opt={}, &test)
				@connection.wait_for(symbol, timeout, opt.merge(:prepare => @block), &test)
			end
		end # Preparation
	end # IRC
end # SilverPlatter
