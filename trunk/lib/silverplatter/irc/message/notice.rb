#--
# Copyright 2007 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module SilverPlatter
	module IRC

		# Message subclass for :PRIVMSG messages
		class Message
			class NOTICE < Message
				def answer(text)
					@connection.send_notice(text, @channel || @from)
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
			end # NOTICE
		end # Message
	end # IRC
end # SilverPlatter
