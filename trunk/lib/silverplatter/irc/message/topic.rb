#--
# Copyright 2007 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module SilverPlatter
	module IRC

		# Message subclass for :TOPIC messages
		class Message
			class TOPIC < Message
				def realm
					:channel
				end

				def public?
					true
				end

				def private?
					false
				end
			end # TOPIC
		end # Message
	end # IRC
end # SilverPlatter
