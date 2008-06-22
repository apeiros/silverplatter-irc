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
		# IRC::ConnectionSet provides connection pooling and method delegation
		# 
		# == Synopsis
		#   # using imperative style
		#   pool = SilverPlatter::IRC::Pool.new
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
		class ConnectionSet
			include Enumerable

			def initialize(*connections)
				@named       = {} # name => [connection, ...], maps names to connections
				@connections = {} # connection => [name, ...], maps connections to names
				add(*connections)
			end
			
			# Unifies two connection-sets, also unifying its names. So if the same connection
			# exists in both sets under different names then it will be known under both in the
			# unification
			def +(other)
				other_con   = other.instance_variable_get(:@connections)
				other_named = other.instance_variable_get(:@named)
				connections = @connections.merge(other_con) { |key, a,b| a|b }
				named       = @named.merge(other_named) { |key, a,b| a|b }
				connection  = Connection.new
				connection.instance_eval {
					@connections = connections
					@named       = named
				}
				connection
			end
			alias | +

			# Create a new ConnectionSet with all connections from the receiver that are not in other
			def -(other)
				connection = dup
				other.each { |con|
					connection.delete(con)
				}
				connection
			end
			
			# Intersection of connections
			def &(other)
				connection  = dup
				other_con   = other.instance_variable_get(:@connections)
				all         = other_con.keys | @connections.keys
				common      = other_con.keys & @connections.keys
				(all-common).each { |con|
					connection.delete(con)
				}
				connection
			end
			
			# Set of exclusive connections to this SonnectionSet and other
			def ^(other)
				(self | other) - (self & other)
			end
			
			# Add unnamed connections, see add_named
			def add(*connections)
				@connections.each { |con|
					names = [
						@connections.port,
						@connections.server,
						":#{@connections.port}",
						"#{@connections.server}:#{@connections.port}",
					]
					@connections[con] ||=  []
					@connections.concat(names)
					names.each { |name|
						@named[name] ||= []
						@named[name]   = con
					}
				}
				self
			end
			
			# Add a name for a connection, see ConnectionPool#[]
			def add_name(connection, name)
				name           = name.to_str
				@named[name] ||= []
				@named[name]  << connection
				@connections[connection] << name
				self
			end
			
			def delete(connection)
				if names = @connections.delete(connection) then
					names.each { |name|
						@named[name].delete(connection)
					}
				end
				self
			end
			
			def delete_name(connection, name)
				if @named[name] then
					@named[name].delete(name)
					@named.delete(name) if @named[name].empty?
				end
				@connections[connection].delete(name)
				self
			end
			
			# accepts a {name => connection} hash
			def add_named(connections={})
				connections.each { |name, con|
					names = [
						name,
						con.port,
						con.server,
						":#{con.port}",
						"#{con.server}:#{con.port}",
					]
					names.each { |name|
						@named[name] ||= []
						@named[name]  << con unless @named[name].include?(con)
					}
					@connections[con] ||= []
					@connections[con].concat(names)
				}
				self
			end
				
			
			# Get a ConnectionPool with matching server and port (or only server or only port)
			# examples:
			#   pool["irc.freenode.org:6667"] # => ConnectionPool, all connections having server="irc.freenode.org" AND port=6667
			#   pool["irc.freenode.org"]      # => ConnectionPool, all connections having server="irc.freenode.org" and any port
			#   pool[":6667"]                 # => ConnectionPool, all connections having any server and port=6667
			#   pool[6667]                    # => ConnectionPool, all connections having any server and port=6667
			#   pool[:name]                   # => ConnectionPool, all connections having name :name
			def [](name)
				case name
					when String, Integer
						ConnectionPool.new(*@named[name])
					else
						ConnectionPool.new(*@named.values_at(*@named.keys.grep(name)).flatten)
				end
			end

			# Iterate over all connections
			def each(&block)
				@connections.each(&block)
			end
			
			# Dispatch a method call to all connections.
			# Exceptions won't be rescued.
			def dispatch(*args, &block)
				rv = {}
				@connections.each_key { |con| rv[con] = con.__send__(*args, &callback) }
				rv
			end
			
			# Dispatch a method call to all connections, rescuing eventually raised exceptions
			# and returning them in place of the return value
			def save_dispatch(*args, &block)
				rv = {}
				@connections.each_key { |con|
					rv[con] = begin; con.__send__(*args, &callback); rescue => e; e; end
				}
				rv
			end
			
			# Calls subscribe with all given parameters on all connections in this pool
			def subscribe(*args, &callback)
				rv = {}
				@connections.each_key { |con| rv[con] = con.subscribe(*args, &callback) }
				rv
			end
			
			# Calls subscribe_once with all given parameters on all connections in this pool
			def subscribe_once(*args, &callback)
				rv = {}
				@connections.each_key { |con| rv[con] = con.subscribe_once(*args, &callback) }
				rv
			end
			
			# connect all connections
			def connect
				rv = {}
				@connections.each_key { |con| rv[con] = con.connect }
				rv
			end
			
			# login all connections
			def login(*args, &block)
				rv = {}
				@connections.each_key { |con| rv[con] = con.login(*args, &block) }
				rv
			end

			# Sends a quit to the server and removes the connection from this client
			def quit(quit_reason=nil)
				rv = {}
				@connections.each_key { |con| rv[con] = con.quit(quit_reason) }
				rv
			end
		end # Client
	end # IRC
end # SilverPlatter
