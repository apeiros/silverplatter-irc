#--
# Copyright 2007 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'silverplatter/irc/channelmodes'
require 'silverplatter/irc/rfc1459_casemapping'
require 'silverplatter/irc/rfc1459_usermodes'
require 'silverplatter/irc/rfc1459_channelmodes'
require 'silverplatter/irc/topic'
require 'silverplatter/irc/userlist'
require 'thread'



module SilverPlatter
	module IRC

		# == Authors
		# * Stefan Rusterholz <apeiros@gmx.net>
		#
		# == About
		# Channel represents a Channel in the IRC network.
		# 
		# == Synopsis
		# 
		#
		# == Description
		# Channel is enumerable over the users in that channel and
		# comparable against the normalized name.
		#
		# == Notes
		#
		# == Known Bugs
		# Currently none.
		# Please inform me about bugs using the bugtracker on
		# http://rubyforge.org/tracker/?atid=17330&group_id=4522&func=browse
		#
		# == See Also
		# * SilverPlatter::IRC
		# * SilverPlatter::IRC::Client
		# * SilverPlatter::IRC::UserList
		# * SilverPlatter::IRC::User
		# * SilverPlatter::IRC::Topic
		# * SilverPlatter::IRC::Connection
		# * SilverPlatter::IRC::ChannelList
		class Channel < UserList
			include RFC1459_UserModes
			include RFC1459_ChannelModes
			include Comparable

			# The name of the channel (immutable)
			attr_reader :name

			# The current topic of the channel
			attr_reader :topic
			
			# The value used for comparison/sorting
			attr_reader :compare
			
			# The modes this channel has (a String with the mode letters)
			attr_reader :mode
			
			# Create a Butler::IRC::Channel-object.
			# If this channel object is a life channel, you should set
			# a connection and notify to true, so the channel gets informed
			# about nickchanges
			def initialize(name, connection=nil)
				super(connection)
				@name    = name.freeze
				@topic   = Topic.new("", nil, nil)
				@compare = casemap(name)
				@mode    = ChannelModes.new
			end
			
			# Add a user, optionally set his flags (will be frozen)
			#   IRC::Channel.new("#test").add_user(IRC::User.new("test"))
			def add_user(user, flags=NoModes)
				@lock.synchronize {
					@users[user] = flags.freeze
				}
			end
			
			# Add a mode specific to this channel to a given user
			# Will silently do nothing in case a user is not (no longer?) in the channel
			# in order to avoid race conditions
			#   channel.add_usermode(some_user, IRC::RFC1459_UserModes::Op) # adds the "o" flag
			def add_usermode(user, modes)
				@lock.synchronize {
					(@users[user] += modes).freeze if @users.include?(user)
				}
			end

			# Remove a mode specific to this channel from a given user
			# Will silently do nothing in case a user is not (no longer?) in the channel
			# in order to avoid race conditions
			def remove_usermode(user, modes)
				@lock.synchronize {
					(@users[user] = @users[user].delete(modes)).freeze if @users.include?(user)
				}
			end
			
			# Test whether a given user has the operator flag set
			#   channel.voice?(some_irc_user)
			def op?(user)
				self[user].include?(@connection ? @connection.usermode_op : Op)
			end
			
			# Test whether a given user has the voice flag set
			#   channel.voice?(some_irc_user)
			def voice?(user)
				self[user].include?(@connection ? @connection.usermode_voice : Voice)
			end
			
			# Comparison based on casemapped channelname
			# If either channel's connection is set, they must be equal too
			# as e.g. irc.freenode.org/#ruby-lang is no the same as irc.undernet.org/#ruby-lang
			def ==(other)
				@compare == other.compare &&
				(!(@connetion || other.connection) || @connection == other.connection)
			rescue NoMethodError
				raise ArgumentError, "Expected #{self.class}, given #{other.class}"
			end
	
			# Comparison based on casemapped channelname, -1, 0 or 1
			def <=>(other)
				@compare <=> other.compare
			rescue NoMethodError
				raise ArgumentError, "Expected #{self.class}, given #{other.class}"
			end
			
			# Returns the (frozen!) name of the channel
			def to_s
				@name
			end

			# If a connection is set, returns server:port:name of the channel, otherwise
			# just :: followed by the normalized name of the channel.
			def to_str #:nodoc:
				@connection ? "#{@connection.server}:#{@connection.port}:#{@compare}" : "::#{@compare}"
			end

			def inspect # :nodoc:
				sprintf "#<%s:0x%x %s %s (%d users)",
					self.class,
					object_id<<1,
					@name,
					@connection,
					size
				# /sprintf
			end

			# Channels can't be duped
			def dup
				raise TypeError, "can't dup #{self.class}"
			end

			# Channels can't be cloned
			def clone
				raise TypeError, "can't clone #{self.class}"
			end
		end # Channel
	end # IRC
end # SilverPlatter
