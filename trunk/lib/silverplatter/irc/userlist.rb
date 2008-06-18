#--
# Copyright 2007 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'silverplatter/irc/channellist'
require 'silverplatter/irc/rfc1459_casemapping'
require 'silverplatter/irc/user'
require 'thread'



module SilverPlatter
	module IRC

		# == Authors
		# * Stefan Rusterholz <apeiros@gmx.net>
		#
		# == About
		# UserList provides a convenient way to keep a list of users with attached
		# information such as what modes they have.
		# 
		# == Synopsis
		#   list = SilverPlatter::IRC::UserList.new
		#   list[user] = "o" # add a user with op flag
		#   list[user] # get the associated value of a user
		#   list.each { |user, flags| puts "#{user.nick} has the flags #{value}" }
		#   list.by_nick(nickname) # get the userobject for which you only know the nick
		#   list.value_by_nick(nickname) # get the associated value
		#   list.delete(user) # delete a user
		#   list.delete_nick(nickname) # delete a user from which you only know the nick
		# 
		# == Description
		# UserList is used to keep a list of user. It can be used standalone, but it is
		# supposed to be used in conjunction with an IRC::Connection which is used for
		# lookups by nick and for the appropriate casemapping.
		# UserList is Enumerable over all users, yielding user => value
		# Lookups by nick will be faster if a connection is set
		#
		# == Notes
		# If you set the connection of the UserList, all users stored in it should
		# use the same connection object.
		#
		# The code assumes Object#dup, Hash#[] and Hash#[] to be atomic, in other
		# words it doesn't synchronize those methods. It also assumes Hash#each,
		# Hash#each_key and Hash#each_value to be working correctly with other threads
		# deleting members while iterating.
		#
		# The connection object is expected to have the following methods:
		# * ==
		# * casemap
		# * user_by_nick
		# 
		# == Known Bugs
		# Currently none
		# Please inform me about bugs using the bugtracker on
		# http://rubyforge.org/tracker/?atid=17330&group_id=4522&func=browse
		#
		# == See Also
		# * SilverPlatter::IRC
		# * SilverPlatter::IRC::Client
		# * SilverPlatter::IRC::User
		# * SilverPlatter::IRC::Connection
		# * SilverPlatter::IRC::Channel
		# * SilverPlatter::IRC::ChannelList
		class UserList
			include RFC1459_CaseMapping
			include Enumerable

			# Provides the mutex that's used to synchronize all mutations.
			# Use UserList#lock.synchronize if you need to test whether a user is present and operate
			# on it thereafter.
			attr_reader :lock
			
			# Returns the connection object this UserList uses for casemapping.
			attr_reader :connection

			# Create a new userlist, if the connection argument is given it will use that
			# objects casemap method for all casemapping of nicknames.
			# All users in the list should use the same connetion as the userlist itself!
			# If notify is set to true, the userlist will tell parser to inform it over
			# nick changes.
			def initialize(connection=nil)
				@users      = {} # User => value
				@lock       = Mutex.new
				@connection = connection
			end

			# Get the value associated with a user
			def [](user)
				@users[user]
			end
			
			# Store a new user with a value
			# Also see IRC::Connection#create_user
			def []=(user, value)
				@users[user] = value
			end
			
			# Test whether a given user is in this userlist.
			def include?(user)
				@users.has_key?(user)
			end

			# Test whether this userlist includes a user with the given nick (casemapped)
			def include_nick?(nick)
				if @connection then
					include?(@connection.user_by_nick(nick))
				else
					nick = casemap(nick)
					@users.any? { |k,v| k.compare == nick }
				end
			end

			# Get a user by nick
			# Also see IRC::Connection#strip_user_prefixes
			# You should use Connection#user_by_nick if you can
			def by_nick(nick)
				if @connection then
					user = @connection.user_by_nick(nick)
					@users.has_key?(user) ? user : nil
				else
					nick = casemap(nick)
					@users.keys.find { |user| user.compare == nick }
				end
			end			

			# Get the associated value of a user by nick
			# Also see IRC::Connection#strip_user_prefixes
			def value_by_nick(nick)
				@lock.synchronize {
					@users[by_nick(nick)]
				}
			end			

			# Return all users in this list if no argument is given
			# With nicknames as arguments it will return an array with the users
			# having the given nicks
			def users(*nicks)
				if nicks.empty? then
					@users.keys
				elsif @connection then
					users = nicks.map { |nick| @connection.user_by_nick(nick) }
					@lock.synchronize {
						users.select { |user| @users.include?(user) }
					}
				else
					nicks = Hash[*nicks.map { [casemap(nick), true] }.flatten]
					@lock.synchronize {
						@users.select { |user| nicks[user.compare] }
					}
				end
			end
			
			# Return all nicks in this list
			def nicks
				@users.map { |user, value| user.nick }
			end
			
			# Return all values associated with users
			def values
				@users.values
			end

			# Returns amount of users in this list
			def size
				@users.size
			end

			# Looks up if there are clones in the list of users (if the same user is in irc
			# under different nicks, those nicks are considered clones).
			# min defines how many users need to have the same host and user to appear in the list.
			# Returns a hash of the form: { hostmask => [matching, users] }
			# Also see weak_clones (weak_clones only needs the same host, strong_clones needs
			# same host and same username)
			def strong_clones(min=2)
				sieve	= Hash.new { |h,k| h[k] = [] }
				@lock.synchronize {
					@users.each_key { |user|
						sieve["*!#{user.user}@#{user.host}"] << user if (user.user && user.host)
					}
				}
				sieve.reject { |host, users| users.size < min }
			end

			# Looks up if there are clones in the list of users (if the same user is in irc
			# under different nicks, those nicks are considered clones).
			# min defines how many users need to have the same host to appear in the list.
			# Returns a hash of the form: { hostmask => [matching, users] }
			# Also see strong_clones (weak_clones only needs the same host, strong_clones needs
			# same host and same username)
			def weak_clones(min=2)
				sieve	= Hash.new { |h,k| h[k] = [] }
				@lock.synchronize {
					@users.each_key { |user|
						sieve["*!*@#{user.host}"] << user if user.host
					}
				}
				sieve.reject { |host, users| users.size < min }
			end

			# iterate over [user, value]
			# be aware that a user might become deleted while you iterate, so a yielded user might no
			# longer be a member of this userlist.
			def each(&block)
				@users.each(&block)
			end
			
			# iterate over users
			# be aware that a user might become deleted while you iterate, so a yielded user might no
			# longer be a member of this userlist.
			def each_user(&block)
				@users.each_key(&block)
			end
			
			# iterates over nicks
			# be aware that a user might become deleted while you iterate, so a yielded nick might no
			# longer be a member of this userlist.
			def each_nick
				@users.each_key { |user| yield(user.nick) }
			end
			
			# iterates over values
			def each_value(&block)
				@users.values.each(&block)
			end
			
			# Delete a user, the reason is passed on to observers
			def delete(user, reason=nil)
				@lock.synchronize { @users.delete(user) }
			end
			
			# Delete a user by nick, the reason is passed on to observers
			def delete_nick(nick, reason=nil)
				delete(by_nick(nick), reason)
			end


			# Delete a channel from all users in this list
			def delete_channel(channel, reason=nil)
				@users.each_key { |user| user.delete_channel(channel, reason) }
			end
			
			# Remove all users from the list
			def clear
				@lock.synchronize { @users.clear }
			end
			
			# Test if userlist is empty
			def empty?
				@users.empty?
			end
			
			# Delegates to this lists lock.
			def synchronize(*args, &block)
				@lock.synchronize(*args, &block)
			end

			def inspect # :nodoc:
				"#<%s:0x%x %s %s (%d users)" %  [self.class, object_id, @name, @connection, size]
			end

			private
			# Return the nick casemapped
			def casemap(nick)
				@connection ? @connection.casemap(nick) : super
			end
		end
	end
end
