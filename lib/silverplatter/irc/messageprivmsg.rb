#--
# Copyright 2007 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module SilverPlatter
	module IRC

		# Message subclass for :PRIVMSG messages
		class MessagePRIVMSG < Message
			def answer(text)
				@connection.send_privmsg(text, @channel || @from)
			end
		end
	end
end
