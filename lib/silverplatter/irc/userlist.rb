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
		#   list.user(nickname) # get the userobject for which you only know the nick
		#   list.value_by_nick(nickname) # get the associated value
		#   list.delete(user) # delete a user
		#   list.delete_nick(nickname) # delete a user from which you only know the nick
		# 
		# == Description
		# UserList is used to keep a list of users. It can be used standalone, but it is
		# supposed to be used in conjunction with an IRC::Connection which is used for
		# lookups by nick and for the appropriate casemapping.
		# UserList is Enumerable over all users, yielding user => value
		# Lookups by nick will be faster if a connection is set
		#
		# == Notes
		# If you set the connection of the UserList, all users stored in it should
		# use the same connection object.
		#
		# The code assumes Hash methods to be ACID.
		#
		# The connection object is expected to have the following methods:
		# * ==
		# * casemap
		# * user
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
			# Accepts either a nick or a User as argument
			# Also see: UserList#value_by_user, UserList#value_by_nick and UserList#user
			def [](user)
				if user.kind_of?(User) then
					@users[user]
				else
					@users[user(user)]
				end
			end
			
			# Associate a value with a user
			# Accepts either a nick or a User as argument
			def []=(user, value)
				if user.kind_of?(User) then
					@users[user] = value
				else
					@users[user(user)] = value
				end
			end

			# Test whether a given user is in this userlist.
			def include?(user)
				if user.kind_of?(User) then
					@users.has_key?(user)
				else
					include_nick?(user)
				end
			end

			# Test whether a given user is in this userlist.
			def include_user?(user)
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
			def user(nick)
				if @connection then
					user = @connection.user_by_nick(nick)
					@users.has_key?(user) ? user : nil
				else
					nick = casemap(nick)
					@users.keys.find { |user| user.compare == nick }
				end
			end

			# Get the value associated with a user
			def value_by_user(user)
				raise TypeError, "User expected, #{user.class} given." unless user.kind_of?(User)
				@users[user]
			end

			# Get the associated value of a user by nick
			# Also see IRC::Connection#strip_user_prefixes
			def value_by_nick(nick)
				@users[by_nick(nick)]
			end			

			# Return all users in this list if no argument is given
			# With nicknames as arguments it will return an array with the users
			# having the given nicks
			def users(*nicks)
				if nicks.empty? then
					@users.keys
				elsif @connection then
					users = nicks.map { |nick| @connection.user_by_nick(nick) }
					users.select { |user| @users.include?(user) }
				else
					nicks = Hash[*nicks.map { [casemap(nick), true] }.flatten]
					@users.select { |user| nicks[user.compare] }
				end
			end
			
			# Return all nicks in this list
			def nicks
				@users.map { |user, value| user.nick }
			end
			
			# Return all values associated with users
			def values(*users)
				users.empty? ? @users.values : @users.values_at(*users)
			end

			# Returns number of users in this list
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
				@users.each_key { |user|
					sieve[user.hostmask(true)] << user if (user.user && user.host)
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
				@users.each_key { |user|
					sieve[user.hostmask(true, true)] << user if user.host
				}
				sieve.reject { |host, users| users.size < min }
			end

			# Users this userlist shares with another one
			#   userlist_a.common_users(userlist_b) # => UserList
			def common_users(with_other)
				common = @users.keys & with_other.users
				users  = @users # @users would refer to the lists @users
				list   = UserList.new(@connection)
				list.instance_eval {
					common.each { |user|
						@users[user] = users[user]
					}
				}
				list
			end
			
			# Whether this userlist shares users with another one			
			def common_users?(with_other)
				!common_users_array(@users.keys & with_other.users).empty?
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
				@users.delete(user)
			end
			alias delete_user delete
			
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
				@users.clear
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
				sprintf "#<%s:0x%08x connection: %08x (%d users)>",
					self.class,
					object_id<<1,
					@connection.object_id<<1,
					size
				# /sprintf
			end

			private
			# Return the nick casemapped
			def casemap(nick)
				@connection ? @connection.casemap(nick) : super
			end
			
			def initialize_copy(template)
				@users      = @users.dup # don't share the users-hash
				@lock       = Mutex.new  # don't share the mutex
			end
		end
	end
end
