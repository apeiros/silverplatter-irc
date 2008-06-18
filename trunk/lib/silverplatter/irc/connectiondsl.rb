#--
# Copyright 2007 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module SilverPlatter
	module IRC

		# == Authors
		# * Stefan Rusterholz <apeiros@gmx.net>
		#
		# == About
		# Helper class used for SilverPlatter::IRC::Connection#new's DSL.
		# 
		# == Known Bugs
		# Currently none.
		# Please inform me about bugs using the bugtracker on
		# http://rubyforge.org/tracker/?atid=17330&group_id=4522&func=browse
		#
		# == See Also
		# * SilverPlatter::IRC
		# * SilverPlatter::IRC::Connection
		class ConnectionDSL
			attr_reader :__config__

			def initialize(server=nil, port=nil, &dsl)
				@__config__ = {}
				server(server) if server
				port(server) if port
				instance_eval(&dsl)
			end
			
			# Used to set the default values, provided by Client
			def inverse_update(defaults) # :nodoc:
				@__config__.replace(defaults.merge(@__config__))
			end

			# Use this server
			def server(val)
				@__config__[:server] = val
			end

			# Password to send the server upon connect
			def serverpass(val)
				@__config__[:serverpass] = val
			end

			# Use this port
			def port(val)
				@__config__[:port] = val
			end

			# Use this nickname
			def nickname(val)
				@__config__[:nickname] = val
			end

			# Use this username
			def username(val)
				@__config__[:username] = val
			end

			# Use this realname
			def realname(val)
				@__config__[:realname] = val
			end
	
			# Send a ping to the server in this interval
			def ping_interval(val)
				@__config__[:ping_interval] = val
			end
	
			# try this many times to reconnect before giving up (-1 means infinite times)
			def reconnect_tries(val)
				@__config__[:reconnect_tries] = val
			end

			# after an unexpected disconnect, wait for this amount of seconds before trying to reconnect
			def reconnect_delay(val)
				@__config__[:reconnect_delay] = val
			end
			
			# The connection invokes the block if at connect the nick you give is rejected
			# It yields |self, originalnick, lastnick, number| where originalnick is the nick
			# as set for the connection, lastnick the nick that was tried the last time and
			# number the number of tries so far.
			def on_nick_error(&block)
				@__config__[:on_nick_error] = block
			end

			# The connection invokes the block if the connection disconnects, it yields |self, reason|,
			# where reason is either :quit (meaning the disconnect as requested by you), :disconnect
			# (the server informed you about disconnecting you, e.g. after a kill), :error (the disconnect
			# happened due to an error and was unexpected), :quit (you told your client to quit and in
			# order got disconnected).
			def on_disconnect(&block)
				@__config__[:on_disconnect] = block
			end
		end # ConnectionDSL
	end # IRC
end # SilverPlatter
