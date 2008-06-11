#--
# Copyright 2007 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'silverplatter/irc/connection'



module SilverPlatter
	module IRC

		# == Indexing
		# * Author:   Stefan Rusterholz
		# * Contact:  apeiros@gmx.net>
		# * Revision: $Revision: 109 $
		# * Date:     $Date: 2008-03-06 11:59:38 +0100 (Thu, 06 Mar 2008) $
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
			end
			
			def subscribe(*args)
				rv = {}
				@connections.each { |key, con| rv[key] = con.subscribe(*args) }
				rv
			end
			
			def subscribe_once(*args)
				rv = {}
				@connections.each { |key, con| rv[key] = con.subscribe_once(*args) }
				rv
			end
			
			def connect_to(server, options=nil)
				connection = Connection.new(server, options || EmptyHash)
				@connections["#{connection.server}:#{connection.port}"] = connection
			end
			
			# Get a connection by "<server>:<port>"
			def [](connection)
				@connections[connection]
			end
			
			# Iterate over all connections
			def each(&block)
				@connections.each(&block)
			end
			
			# Sends a quit to the server and removes the connection from this client
			def disconnect_from(connection, quit_reason=nil)
				raise ArgumentError, "No connection '#{connection}' available" unless con = @connections[connection]
				con.quit(quit_reason, true) if con.connected?
				@connections.delete(connection)
				true
			end
		end
	end # IRC
end # SilverPlatter
