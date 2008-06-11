#--
# Copyright 2007 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module SilverPlatter
	module IRC

		# Message subclass for :PRIVMSG messages
		class Message
			class PRIVMSG < Message
				def answer(text)
					@connection.send_privmsg(text, @channel || @from)
				end

				def realm
					@channel ? :channel : :private
				end

				def public?
					@channel.nil?
				end

				def private?
					!@channel
				end
			end # PRIVMSG
		end # Message
	end # IRC
end # SilverPlatter
