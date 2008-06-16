#--
# Copyright 2007 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'silverplatter/irc/rfc1459_casemapping'
require 'thread'



module SilverPlatter
	module IRC

		# == Indexing
		# * Author:   Stefan Rusterholz
		# * Contact:  apeiros@gmx.net
		# * Revision: $Revision: 139 $
		# * Date:     $Date: 2008-03-14 17:47:29 +0100 (Fri, 14 Mar 2008) $
		#
		# == About
		# ChannelList provides a convenient way to keep a list of channels with attached
		# information.
		# 
		# == Synopsis
		#   list = SilverPlatter::IRC::ChannelList.new
		#   list[channel] = "foobar" # add a channel
		#   list[channel] # get the associated value for a channel
		#   list.each { |channel, data| puts "#{channel.name} has the data #{data}" }
		#   list.by_name(channelname) # get the channel-object for which you only know the name
		#   list.value_by_name(channelname) # get the associated value
		#   list.delete(channel) # delete a channel
		#   list.delete_name(channelname) # delete a channel from which you only know the name
		# 
		# == Description
		# If used within an IRC client it should be attached to a connection
		# to use the same casemapping.
		# ChannelList is Enumerable over all channels, yielding channel => value
		#
		# == Notes
		# If you set the connection of the ChannelList, all channels stored in it should
		# use the same connection object.
		#
		# The code assumes Object#dup, Hash#[] and Hash#[] to be atomic, in other
		# words it doesn't synchronize those methods.
		# 
		# == Known Bugs
		# Currently none
		# Please inform me about bugs using the bugtracker on
		# http://rubyforge.org/tracker/?atid=17330&group_id=4522&func=browse
		#
		# == See Also
		# * SilverPlatter::IRC
		# * SilverPlatter::IRC::Client
		# * SilverPlatter::IRC::Channel
		# * SilverPlatter::IRC::Connection
		# * SilverPlatter::IRC::User
		# * SilverPlatter::IRC::UserList
		class ChannelList
			include Enumerable
			include RFC1459_CaseMapping

			# Provides the mutex that's used to synchronize all mutations
			attr_reader :lock

			# Returns the connection object this ChannelList uses for casemapping
			attr_reader :connection

			# Create a new channellist, if the connection argument is given it will use that
			# objects casemap method for all casemapping of channelnames.
			# All channels in the list should use the same connetion as the channellist itself!
			def initialize(connection=nil)
				@channels   = {} # Channel => value
				@lock       = Mutex.new
				@connection = connection
			end
			
			# Delegates to this lists lock.
			def synchronize(*args, &block)
				@lock.synchronize(*args, &block)
			end

			# Get the value associated with a channel
			def [](channel)
				@channels[channel]
			end

			# Store a new channel with a value
			# Also see IRC::Connection#create_channel
			def []=(channel, value)
				@channels[channel]      = value
			end

			# Get a channel by name
			def by_name(name)
				if @connection then
					channel = @connection.channel_by_name(name)
					@channels.has_key?(channel) ? channel : nil
				else
					name = casemap(name)
					@channels.keys.find { |channel| channel.compare == name }
				end
			end			

			# Test whether a given channel is in this channellist.
			def include?(user)
				@channels.has_key?(user)
			end

			# Test whether this channellist includes a channel with the given name (casemapped)
			def include_name?(name)
				if @connection then
					include?(@connection.channel_by_name(name))
				else
					name = casemap(name)
					@channels.any? { |k,v| k.compare == name }
				end
			end

			# Get the associated value of a channel by name
			def value_by_name(name)
				@lock.synchronize {
					@channels[by_name(name)]
				}
			end			

			# Return all channels in this list if no argument is given
			# With channelnames as arguments it will return an array with the channels
			# having the given names
			def channels(*names)
				if names.empty? then
					@channels.keys
				elsif @connection then
					names = names.map { |name| @connection.channel_by_name(name) }
					@lock.synchronize {
						names.select { |name| @channels.include?(name) }
					}
				else
					names = Hash[*names.map { [casemap(name), true] }.flatten]
					@lock.synchronize {
						@channels.select { |channel| names[channel.compare] }
					}
				end
			end

			# Return all names in this list (casemapped to lowercase)
			def names
				@channels.map { |channel, value| channel.name }
			end

			# Return all values associated with channels
			def values
				@channels.values
			end

			# Returns amount of channels in this list
			def size
				@channels.size
			end

			# Channels this channellist shares with another one
			def common_channels(with_other)
				@channels.keys & with_other.channels
			end
			
			# Whether this channellist shares channels with another one
			def common_channels?(with_other)
				!common_channels(with_other).empty?
			end

			# Iterate over [channel, value]
			def each(&block)
				@channels.dup.each(&block)
			end

			# Iterate over channels
			def each_channel(&block)
				@channels.keys.each(&block)
			end

			# Iterates over names
			def each_name(&block)
				@channels.keys.each { |channel| yield(channel.name) }
			end

			# Iterates over values
			def each_value(&block)
				@channels.values.each(&block)
			end

			# Delete a channel, the reason is passed on to observers
			def delete(channel, reason=nil)
				@lock.synchronize { @channels.delete(channel) }
			end

			# Delete a channel by name, the reason is passed on to observers
			def delete_name(name, reason=nil)
				delete(by_name(name), reason)
			end


			# Delete a user from all channels in this list
			def delete_user(user, reason=nil)
				@channels.each_key { |user| user.delete_user(user, reason) }
			end

			# Test if channellist is empty
			def empty?
				@channels.empty?
			end

			# Remove all channels from the list
			def clear
				@lock.synchronize { @channels.clear }
			end

			def inspect # :nodoc:
				"#<%s:0x%x %s (%d users)" %  [self.class, object_id, @connection, size]
			end

			private
			# Return the string casemapped
			def casemap(string)
				@connection ? @connection.casemap(string) : super
			end
		end
	end
end
