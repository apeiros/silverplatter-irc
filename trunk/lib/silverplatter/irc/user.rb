#--
# Copyright 2007 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'silverplatter/irc/channellist'
require 'silverplatter/irc/rfc1459_casemapping'
require 'silverplatter/irc/rfc1459_usermodes'



module SilverPlatter
	module IRC

		# == Indexing
		# * Author:   Stefan Rusterholz
		# * Contact:  apeiros@gmx.net
		# * Revision: $Revision: 147 $
		# * Date:     $Date: 2008-03-21 16:55:07 +0100 (Fri, 21 Mar 2008) $
		#
		# == About
		#	The User class is used to store users and attached infos, e.g. channels
		# it shares with the client, modes it has in those channels, hostname etc.
		# 
		# == Synopsis
		# 
		# == Description
		#
		# == Notes
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
		# * SilverPlatter::IRC::ChannelList
		# * SilverPlatter::IRC::Client
		# * SilverPlatter::IRC::User
		# * SilverPlatter::IRC::Connection
		# * SilverPlatter::IRC::Channel
		class User < ChannelList
			include RFC1459_CaseMapping
			include RFC1459_UserModes
			include Comparable
			include Enumerable

			# Temporary User#compare value if no nick is given
			Incomparable  = "\xff".freeze

			# nickname of a user
			attr_reader :nick

			# username of a user
			attr_reader :user

			# hostpart of a user
			attr_reader :host

			# realname of a user
			attr_reader :real
	
			# lowercase nickname (casemapping defaults to rfc1459, will use parsers casemapping if
			# available to conform to connection setting)
			attr_reader :compare
			
			# The away message of a user, nil of not away
			attr_accessor :away
			
			# last time the SilverPlatter::IRC::Connection has seen this user
			attr_reader :last_seen
	
			attr_writer :myself # :nodoc:

			def initialize(nick=nil, user=nil, host=nil, real=nil, connection=nil)
				super(connection)

				@nick, @user, @host, @real = nil

				@nick       = nick.freeze if nick
				@user       = user.freeze if user
				@host       = host.freeze if host
				@real       = real.freeze if real
				@last_seen  = Time.now

				set_compare

				@channels   = Hash.new(NoFlags) # IRC::Channel => flags
				@myself     = false
				@away       = nil
			end

			# Returns whether this user represents the client
			def me?
				@myself
			end

			# Iterate over all channels this user shares with your client
			def each(&block)
				@channels.each_key(&block)
			end	

			# Return the channels this user shares with your client
			def channels
				@channels.keys
			end
			
			# set users nickname
			def nick=(nick) #:nodoc:
				@nick     = nick.freeze
				set_compare
			end
	
			# check if user has op (+o) in given channel (String or SilverPlatter::IRC::Channel)		
			def op?(in_channel)
				raise TypeError, "Channel required, #{in_channel.class} given" unless Channel === in_channel
				@channels[in_channel].include?(Op)
			end
	
			# check if user has voice (+v) in given channel (String or SilverPlatter::IRC::Channel)		
			def voice?(in_channel)
				raise TypeError, "Channel required, #{in_channel.class} given" unless Channel === in_channel
				@channels[in_channel].include?(Voice)
			end
	
			# check if user has uop (+u) in given channel (String or SilverPlatterIRC::Channel)		
			def uop?(in_channel)
				raise TypeError, "Channel required, #{in_channel.class} given" unless Channel === in_channel
				@channels[in_channel].include?(Uop)
			end
			
			# Check if user is in channel, will not perform a whois, so it only works if the client
			# is also in the channel
			def in?(channel)
				raise TypeError, "Channel required, #{channel.class} given" unless Channel === channel
				@channels.has_key?(channel)
			end
	
			# check if user is away
			def away?
				!!@away
			end

			# A SilverPlatter::IRC::Hostmask instance representing the hostmask of this user
			# To ensure a complete hostmask, do a who(nickname) first.
			def hostmask(wildnick=false, wilduser=false, wildhost=false)
				Hostmask.new(
					!wildnick && @nick || '*',
					!wilduser && @user || '*',
					!wildhost && @host || '*',
					@parser
				)
			end
	
			# Returns the (frozen!) nickname of the user
			def to_s
				@nick
			end

			# If a connection is set, returns server:port:nick of the User, otherwise
			# just :: followed by the normalized name of the User.
			def to_str #:nodoc:
				@connection ? "#{@connection.server}:#{@connection.port}:#{@compare}" : "::#{@compare}"
			end
			
			# Compares two SilverPlatter::IRC::User's based on available information
			# That means a `user = SilverPlatter::IRC::User.new` which has no
			# information set will be == to any other User.
			def ==(other)
				other.kind_of?(User) && (
					(!(@server && other.server) || @compare == other.compare) &&
					(!(@nick && other.nick)     || @compare == other.compare) &&
					(!(@user && other.user)     || @user == other.user) &&
					(!(@host && other.host)     || @host == other.host) &&
					(!(@real && other.real)     || @real == other.real)
				)
			end

			# Compares nicknames
			def <=>(other)
				@compare <=> other.compare
			end
	
			def inspect # :nodoc:
				"#<%s:0x%x %s!%s@%s (%s) in %s>" %  [
					self.class,
					object_id,
					@nick || "?",
					@user || "?",
					@host || "?",
					@real || "?",
					@channels.keys.map { |c| c.name }
				]
			end
			
			# Users can't be duped
			def dup
				raise TypeError, "can't dup #{self.class}"
			end

			# Users can't be cloned
			def clone
				raise TypeError, "can't clone #{self.class}"
			end

			# parser methods

			# This method is intended to be used by IRC::Parser or IRC::Client
			# in case the server alters parts about 'myself'
			# examples: some ircd's change the 'user' part (prefix it), some
			# ircd's allow hiding the host, ...
			def update(user=nil, host=nil, real=nil) #:nodoc:
				@user = user.freeze if user
				@host = host.freeze if host
				@real = real.freeze if real
				self
			end

<<<<<<< .mine
			# Change the visibility of this user, returns whether the status has changed or not
			def change_visibility(new_visibility)
				changed     = (@visibility != new_visibility)
				@last_seen  = Time.now
				@visibility = new_visibility
				changed
=======
			# Change the status of this user, returns whether the status has changed or not
			def change_status(new_status)
				raise ArgumentError, "Invalid new status #{new_status.inspect}, see User::Status" unless Status.include?(new_status)
				@offline_since = @out_of_sight_since = nil
				case new_status
					when :offline then @offline_since = Time.now
					when :out_of_sight then @out_of_sight_since = Time.now
				end
				@status != (@status = new_status) # yes, this actually works (at least in 1.8.6)
>>>>>>> .r149
			end
			
			# Set the last_seen time to now
			def update_last_seen
				@last_seen = Time.now
			end
			
			# True if the user shares a channel with the SilverPlatter::IRC::Connection
			def visible?
				@visibility
			end
			
			# True if the user shares no channel with the SilverPlatter::IRC::Connection
			def invisible?
				@visibility
			end

			# This method is intended to be used by IRC::Parser or IRC::Client
			# add a channel to the user (should only be used by SilverPlatter::IRC::Parser)
			def add_channel(channel) #:nodoc:
				raise TypeError, "Channel required, #{channel.class} given" unless Channel === channel
				@channels[channel] = "" unless @channels.has_key?(channel)
			end
	
			# remove a channel from the user (should only be used by SilverPlatter::IRC::Parser)
			def delete_channel(channel) #:nodoc:
				raise TypeError, "Channel required, #{channel.class} given" unless Channel === channel
				@channels.delete(channel)
			end
	
			# user.add_flag(@channels["#foo], "@")
			def add_flag(channel, flag) #:nodoc:
				raise ArgumentError, "User #{self} is not listed in #{channel}" unless @channels.has_key?(channel)
				raise ArgumentError, "Invalid flag '#{flag}'" unless Flags.include?(flag)
				current            = @channels[channel]
				@channels[channel] = (current+flag).split.sort.join unless current.include?(flag)
			end

			# user.delete_flag(@channels["#foo], "@")
			def delete_flag(channel, flag) #:nodoc:
				raise ArgumentError, "User #{self} is not listed in #{channel}" unless @channels.has_key?(channel)
				raise ArgumentError, "Invalid flag '#{flag}'" unless Flags.include?(flag)
				@channels[channel] = @channels[channel].delete(flag)
			end
			
			private
			# set @compare to casemapped nick, use @parser.casemap if available, else use rfc1459
			def set_compare
				@compare = if @nick then
					if @connection then
						@connection.casemap(@nick).freeze
					else
						casemap(@nick).freeze
					end
				else
					Incomparable
				end
			end
		end # User
	end
end
