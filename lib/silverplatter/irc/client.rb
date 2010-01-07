#--
# Copyright 2007 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'silverplatter/irc/connection'



module SilverPlatter
	module IRC

		# == Authors
		# * Stefan Rusterholz <apeiros@gmx.net>
		#
		# == About
		# IRC::Client represents a whole irc client, capable of multiple connections.
		# 
		# == Synopsis
		#   # using imperative style
		#   client = SilverPlatter::IRC::Client.new
		#   client.connect_to("irc.freenode.org")
		#   client["irc.freenode.org:6667"].login("mynick", "myuser", "myreal")
		#   client["irc.freenode.org:6667"].send_join("#mychannel")
		#   client["irc.freenode.org:6667"].channels.each_channel { |channel| puts channel }
		#   client["irc.freenode.org:6667"].subscribe(:PRIVMSG) { |message, listener|
		#     $chatlog.puts message.text
		#   }
		#   client["irc.freenode.org:6667"].send_quit("Demo is over")
		#   client.disconnect_from("irc.freenode.org:6667")
		# 
		#   # using the DSL
		#   client = SilverPlatter::IRC::Client.new do
	  #     server    "irc.freenode.org"
	  #     port      6667
	  #     auto_join %w[#mychannel]
	  #   end
	  #   client.run
		#
		# == Description
		# ...
		#
		# == Known Bugs
		# Currently none
		# Please inform me about bugs using the bugtracker on
		# http://rubyforge.org/tracker/?atid=17330&group_id=4522&func=browse
		#
		# == See Also
		# * SilverPlatter::IRC
		# * SilverPlatter::IRC::Connection
		class Client
			include Enumerable

			# An empty hash
			EmptyHash = {}.freeze

			def initialize
				@connections = {}
				@connections_noport = {}
			end
			
			def subscribe(*args, &callback)
				rv = {}
				@connections.each { |key, con| rv[key] = con.subscribe(*args, &callback) }
				rv
			end
			
			def subscribe_once(*args, &callback)
				rv = {}
				@connections.each { |key, con| rv[key] = con.subscribe_once(*args, &callback) }
				rv
			end
			
			def connect_to(server, options=nil)
				connection = Connection.new(server, options || EmptyHash)
				@connections["#{connection.server}:#{connection.port}"] = connection
				if @connections_noport.has_key?(connection.server) then
					@connections_noport.delete(connection.server)
				else
					@connections_noport[connection.server] = connection
				end
			end
			
			# Get a connection by "<server>:<port>", or if there's no other connection
			# to the same server on a different port, just "<server>".
			def [](connection)
				@connections[connection] || @connections_noport[connection]
			end
			
			# Iterate over all connections
			def each(&block)
				@connections.each(&block)
			end
			
			# Sends a quit to the server and removes the connection from this client
			def disconnect_from(connection, quit_reason=nil)
				raise ArgumentError, "No connection '#{connection}' available" unless con = @connections[connection]
				con.quit(quit_reason, true) if con.connected?
				@connections.delete("#{connection.server}:#{connection.port}")
				@connections_noport.delete(connection.server)
				true
			end
		end # Client
	end # IRC
end # SilverPlatter
