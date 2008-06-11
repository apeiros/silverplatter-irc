#--
# Copyright 2007 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module SilverPlatter
	module IRC

		# == Indexing
		# * Author:   Stefan Rusterholz
		# * Contact:  apeiros@gmx.net>
		# * Revision: $Revision: 115 $
		# * Date:     $Date: 2008-03-08 21:24:59 +0100 (Sat, 08 Mar 2008) $
		#
		# == About
		# Helper class used for SilverPlatter::IRC::Client#new's DSL.
		# 
		# == Synopsis
		# 
		#
		# == Description
		# 
		#
		# == Notes
		#
		# == Known Bugs
		# Currently none.
		# Please inform me about bugs using the bugtracker on
		# http://rubyforge.org/tracker/?atid=17330&group_id=4522&func=browse
		#
		# == See Also
		# * SilverPlatter::IRC
		# * SilverPlatter::IRC::Client
		# * SilverPlatter::IRC::ConnectionDSL
		class ClientDSL < ConnectionDSL
			attr_reader :__config__

			def initialize(&dsl)
				super(&dsl)
				if @__config__[:connection] then
					defaults = @__config__.dup
					defaults.delete(:connection)
					@__config__[:connection].each_value { |con|
						con.inverse_update(defaults)
					}
				end
			end

			def connection(name, &block)
				@__config__[:connection] ||= {}
				@__config__[:connection][name] = ConnectionDSL.new(&block)
			end
		end # ClientDSL
	end # IRC
end # SilverPlatter
