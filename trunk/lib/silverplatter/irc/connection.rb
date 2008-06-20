#--
# Copyright 2007 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'silverplatter/irc/ascii_casemapping'
require 'silverplatter/irc/channel'
require 'silverplatter/irc/channellist'
require 'silverplatter/irc/connectiondsl'
require 'silverplatter/irc/listener'
require 'silverplatter/irc/parser'
require 'silverplatter/irc/preparation'
require 'silverplatter/irc/rfc1459_casemapping'
require 'silverplatter/irc/rfc1459strict_casemapping'
require 'silverplatter/irc/socket'
require 'silverplatter/irc/subscriptions'
require 'silverplatter/irc/userlist'
require 'silverplatter/irc/user'
require 'silverplatter/irc/usermanager'
require 'timeout'



module SilverPlatter
	module IRC

		# == Authors
		# * Stefan Rusterholz <apeiros@gmx.net>
		#
		# == About
		# A connection to a single irc server, managing users, channels and other
		# data belonging to it.
		# 
		# == Synopsis
		#   irc = SilverPlatter::IRC::Connection.new "irc.freenode.org"
		#   irc.connect
		# 
		# == Description
		# Parses messages, automatically converts them to
		# SilverPlatter::IRC::Messages (or descendants), knows about the user representing
		# itself, provides highlevel methods that collect commands in reply of queries
		# (e.g. who, whois, chanlist, banlist etc.) and several other services.
		# allows creation of dialogs from privmsg and notice messages
		# Connection is the hub between parser, users, channels, usermanager and
		# itself.
		#
		# == Notes
		# A User has two possible states in relation to a connection:
		# * visible: the user shares at least one channel with the connection's User (connection.me)
		# * invisible: the user was seen quitting (or being killed) or doesn't share any channel
		# The connections own UserList will drop users on leave_server (quit, kill, ...), it will
		# retain users that leave_channel (part, kick, ...) and become invisible. This is to help
		# keeping
		#
		# If you set the connection of the UserList, all users stored in it should
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
		# * SilverPlatter::IRC::User
		# * SilverPlatter::IRC::Connection
		# * SilverPlatter::IRC::Channel
		# * SilverPlatter::IRC::ChannelList
		#
		class Connection < Socket

			# This is the proc that is used per default for &on_nick_error in Connection#login
			RaiseOnNickError = proc { |connection, original_nick, current_nick, tries|
				raise "Nick #{current_nick} is already in use"
			}
			
			# This proc can be used as &on_nick_error with Connection#login
			# It will prefix the nick with [<digit] with <digit> growing by 1 per try.
			# E.g. first try is 'butler', then '[1]butler', '[2]butler' and so on.
			IncrementOnNickError = proc { |connection, original_nick, current_nick, tries|
				"[#{tries}]#{original_nick}"
			}

			# A hash with all options available in addition to SilverPlatter::IRC::Socket::DefaultOptions
			DefaultOptions = {
				:port              => 6667,
				:eol               => "\r\n".freeze,
				:logger            => nil,
				:client_encoding   => "utf-8".freeze,
				:server_encoding   => "utf-8".freeze,
				:channel_encoding  => nil,
				:case_mapping      => 'ascii'.freeze,
				:max_users_backlog => 8192, # maximum number of users offline/out_of_sight
				:max_users_age     => 3*3600, # maximum age of users that are offline/out_of_sight
			}
			
			DropOnStatus = [:out_of_sight, :unknown].freeze # :nodoc:

			# The encoding of the client (defaults to utf-8)
			attr_accessor :client_encoding
			
			# The default encoding of the server (defaults to utf-8)
			attr_accessor :server_encoding
			
			# A hash with the encodings of individual channels
			attr_reader   :channel_encoding
			
			# The SilverPlatter::IRC::User that represents the client of this connection
			attr_reader   :me
			
			# The callback invoked when the client is disconnected
			attr_accessor :disconnect_callback
			
			# Defaults used e.g. when loging in
			# Keys:
			# * :nick - nickname
			# * :user - username
			# * :real - realname
			# * :join - channels to join after logging in
			attr_reader   :default
			
			# The parser instance. Should only be used by connection and parser-commands.
			attr_reader   :parser
			

			# Server is the irc-server to connect
			# you can pass a block which is executed on disconnect with the arguments
			# connection and reason. Possible values for reason are:
			# * :quit:       the connection was programmatically quit, this means you should not try to reconnect
			# * :disconnect: the server stopped responding or the socket raised an error. A reconnect attempt should be made after waiting a bit
			# * :noconnect:  the attempt to connect failed. You should wait before retrying.
			# The options argument is a hash, see DefaultOptions constant for possible values.
			#
			# There are 3 ways to create a new Connection object:
			#   con1 = SilverPlatter::IRC::Connection.new("irc.example.com", :port => 8001)
			#   con2 = SilverPlatter::IRC::Connection.new(nil, :server => "irc.example.com", :port => 8001)
			#   con3 = SilverPlatter::IRC::Connection.new do
			#     server "irc.example.com"
			#     port   8001
			#   end
			def initialize(server=nil, options={}, &description)
				options.update(ConnectionDSL.new(server, &description).__config__) if description
				options[:server]   ||= server # options overrides server
				DefaultOptions.each { |k,v| # prefer over merge as it allows to have nil values replaced
					options[k] ||= v
				}
				options[:username] ||= options[:nickname]
				options[:realname] ||= "#{options[:nickname]} (silverplatter-irc)"

				@events              = {}
				@logger              = options.delete(:logger)
				@nicknames           = {} # map nicks to users
				@channelnames        = {} # map channelnames to channels
				@channels            = ChannelList.new(self) # list of all channels
				@users               = UserList.new(self) # list of all users
				@usermanager         = UserManager.new(self, @users, options.delete(:max_users_backlog), options.delete(:max_users_age))
				@subscriptions       = Subscriptions.new
				@message_lock        = Mutex.new #
				@client_encoding     = options.delete(:client_encoding)
				@server_encoding     = options.delete(:server_encoding)
				@channel_encoding    = Hash.new { @server_encoding } # @server_encoding might change
				@reconnect_tries     = options.delete(:reconnect_tries)
				@reconnect_delay     = options.delete(:reconnect_delay)
				@events[:disconnect] = options.delete(:on_disconnect)
				@events[:nick_error] = options.delete(:on_nick_error) || RaiseOnNickError
				@ping_interval       = options.delete(:ping_interval)
				@case_mapping        = options.delete(:case_mapping)
				@ping_delay          = options.delete(:ping_delay)
				@ping_loop           = nil
				@me                  = nil
				@read_thread         = Thread.new {} # create a dead thread which can be tested for .alive?
				@parser              = Parser.new(self, "rfc2812", "generic")
				@default             = {
					:serverpass => options.delete(:serverpass),
					:nickname   => options.delete(:nickname),
					:username   => options.delete(:username),
					:realname   => options.delete(:realname),
					:join       => options.delete(:join),
				}

				@mutex_whois         = Mutex.new

				@channel_encoding.merge(options[:channel_encoding]) if options[:channel_encoding]
				options.delete(:channel_encoding)

				super(nil, options)
				
				@read_thread.join
			end
			
			def event(name, *args)
				cb = @events[name]
				cb.call(*args)
			end

			# An OpenStruct containing all isupport values of the server (lowercased and symbolified)
			def isupport
				@parser.isupport
			end

			# Subscribe to one, many or all messages (by symbol)
			# Creates a new Listener, subscribes (see subscribe_listener) and
			# returns it.
			# See IRC::SilverPlatter::Listener::new for more info.
			def subscribe(symbols=nil, priority=0, *args, &callback)
				listener = Listener.new(symbols, priority, *args, &callback)
				@subscriptions.subscribe(listener)
				listener
			end
			
			# Same as #subscribe, but the listener is automatically deleted after the first
			# invocation.
			def subscribe_once(symbols=nil, priority=0, *args, &callback)
				listener = Listener.new(symbols, priority, *args) { |listener, *args|
					listener.unsubscribe
					callback.call(listener, *args)
				}
				@subscriptions.subscribe(listener)
				listener
			end

			# Subscribe a Listener object (or any object emulating the interface of
			# SilverPlatter::IRC::Listener).
			def subscribe_listener(listener)
				@subscriptions.subscribe(listener)
				listener
			end

			# Remove a listener from the subscribtions.
			def unsubscribe(listener)
				@subscriptions.unsubscribe(listener)
			end

			# Tests whether two connections are equal. They are if the server and port is the same.
			def ==(other)
				(@server == other.server) && (@port == other.port)
			end
			
			# Should only be used by the Parser
			# Create a new User if necessary or update an old one, returns the new or existing User.
			# FIXME: might be streamlineable
			def create_user(nick, user=nil, host=nil, real=nil) # nicklist, userlist
				new_user, old_user = nil, nil
				@users.synchronize {
					new_user	= User.new(nick, user, host, real, self)
					if old_user = @nicknames[new_user.compare]
						if old_user == new_user then
							update_user_unsynchronized(old_user, nick, user, host, real)
							new_user = old_user

						# if old user was out of sight the new user overrides the old
						elsif old_user.invisible? then
							@nicknames.delete(old_user.compare)
							@nicknames[new_user.compare]	= new_user
							@users[new_user] = true
							@users.delete(old_user)
	
						# thanks to the FU that is IRC, some ircds change hosts w/o notification, so:
						elsif old_user.visible? then 
							update_user(old_user, nick, user, host, real)

						else
							@nicknames.delete(old_user.compare)
							@nicknames[new_user.compare]	= new_user
							@users[new_user] = true
							@users.delete(old_user)
						end
					else
						@nicknames[new_user.compare]	= new_user
						@users[new_user] = true
					end
				}
				new_user
			end

			# Should only be used by the Parser
			# Updates the information of a User
			def update_user(user_obj, nick, user=nil, host=nil, real=nil) # :nodoc:
				@users.synchronize {
					update_user_unsynchronized(user_obj, nick, user, host, real)
				}
				self
			end

			# Should only be used by the Parser
			# Deletes a user, returns whether a User has been actually deleted
			def delete_user(user, reason=nil) # :nodoc:
				if user.change_visibility(false) then
					# FIXME: inform UserManager
				end
				@users.synchronize {
					!!(@nicknames.delete(user.compare) || @users.delete(user))
				}
			end
			
			# Should only be used by the parser
			# Create a Channel if necessary. Returns the new or existing Channel.
			def create_channel(name) # :nodoc:
				@channels.synchronize {
					channel = (@channelnames[casemap(name)] ||= Channel.new(name, self))
					@channels[channel] = true
					channel
				}
			end
			
			# Should only be used by the parser
			# Delete a channel, returns whether a channel has been actually deleted
			def delete_channel(name, reason=nil) # :nodoc:
				@channels.synchronize {
					!!(@channels.delete(channel) || @channelnames.delete(channel.compare))
				}
			end

			# If called without arguments it will return a UserList with all known users in this connection
			# If called with arguments it will return an Array with users mapped to those nicks (possibly nil)
			def users(*nicks)
				if nicks.empty? then
					@users
				else
					@message_lock.synchronize {
						@nicknames.values_at(*nicks.map { |nick| casemap(nick) })
					}
				end
			end

			# If called without arguments it will return a ChannelList with all known channels in this connection
			# If called with arguments it will return an Array with channels mapped to those names (possibly nil)
			def channels(*names)
				if names.empty? then
					@channels
				else
					@message_lock.synchronize {
						@channelnames.values_at(*names.map { |name| casemap(name) })
					}
				end
			end

			# Get a user by his nickname (the method takes care of casemapping)
			def user_by_nick(nick) # => User
				@message_lock.synchronize {
					@nicknames[casemap(nick)]
				}
			end

			# Get a channel by its name (the method takes care of casemapping)
			def channel_by_name(name) # => Channel
				@message_lock.synchronize {
					@channelnames[casemap(name)]
				}
			end
			
			# test whether two nicknames are the same, e.g. according to RFC1459-strict the
			# following nicknames are the same: same_nickname?("foo{}", "FoO[]") # => true
			def same_nick?(a, b) # => true/false - casemapped comparison
				casemap(a) == casemap(b)
			end

			# test whether two channelnames are the same, e.g. according to RFC1459-strict the
			# following channelnames are the same: same_channelname?("#foo{}", "#FoO[]") # => true
			def same_channelname?(a, b) # => true/false - casemapped comparison
				casemap(a) == casemap(b)
			end
			
			# login under nick, user, real - the fourth argument accepts a serverpassword in
			# case the server requires one
			# Login will automatically change the nick if the server reports that the provided
			# one is in use. You can supply a block to change the way the nick is changed. The
			# block receives the parameters: self, originalnick, lastnick, number. Nick
			# represents the nick that was rejected and changes the number of changes so far.
			# The block must return the new nick to use.
			def login(nick=nil, user=nil, real=nil, serverpass=nil, &on_nick_error)
				nick          ||= @default[:nickname]
				user          ||= @default[:username]
				real          ||= @default[:realname]
				serverpass    ||= @default[:serverpass]
				on_nick_error ||= @events[:nick_error] || RaiseOnNickError
				nick_change     = nil
				number          = 0
				@me             = create_user(nick, nil, nil, real)
				@me.instance_variable_set(:@me, true)
				@events[:old_nick_error] = @events[:nick_error]
				@events[:nick_error] = proc {
					@me.nick = @events[:old_nick_error].call(self, nick, @me.nick, number+=1)
					send_nick(@me.nick)
				}

				if @read_thread.alive? then
					prepare do
						super(nick, user, real, serverpass)
					end.wait_for :RPL_WELCOME
				else # can't use wait_for if there's no read_thread running
					super(nick, user, real, serverpass)
					begin
						message = read_message
					end until [:RPL_WELCOME, :ERR_NOMOTD].include?(message.symbol)
				end

				true
			ensure
				@events[:nick_error] = @events.delete(:old_nick_error)
			end

			# Quits, closes the connection and updates all users (visibility)
			def quit(reason=nil)
				prepare do
					send_quit(reason)
				end.wait_for :ERROR # rfc2812, 3.1.7, Servers acknowledge a QUIT with an ERROR
				close
				self
			end

			# blocks current thread until a Message with symbol
			# (optionally passing a test given as block) is received,
			# returns the message received that matches.
			# returns nil if it times out before a match
			# options:
			# * :priority: the priority the listener uses (defaults to 0)
			# * :prepare: a proc object (or any object responding to #call) run after the listener has been set up and before blocking
			# also see Connection#prepare
			# 
			# === Synopsis
			#   # wait until we get the message that we retained op status
			#   wait_for(:MODE) { |message| test_if_message_is_the_wanted_one }
			#   wait_for(:FOO, :prepare => proc { do_something })
			def wait_for(symbol, timeout=nil, opt={}, &test)
				listener = nil
				timeout(timeout) {
					queue    = Queue.new
					listener = subscribe(symbol, opt.delete(:priority)) { |l, m| queue.push(m) }
					opt[:prepare].call if opt.has_key?(:prepare)
					begin
						message = queue.shift
					end until(!block_given? || yield(message))
					message
				}
			rescue Timeout::Error
				nil
			ensure
				listener.unsubscribe
			end
			
			# prepare do preparation_stuff end.wait_for :SYMBOL is the same as
			# wait_for :SYMBOL, :prepare => proc do stuff end
			# you can alternatively supply a callable object as first argument.
			def prepare(callback=nil, &block)
				Preparation.new(self, callback || block)
			end

			# listens for all Messages with symbol (optionally
			# passing a test given as block) and pushes them onto the Queue
			# returns the Queue, extended with Filter.
			# You are responsible to unsubscribe it (via Queue#unsubscribe).
			def filter(symbol, priority=0, queue=Queue.new)
				raise ArgumentError, "Invalid Queue #{queue}:#{queue.class}" unless queue.respond_to?(:push)
				listener = if block_given? then
					subscribe(symbol, priority) { |l, message| queue.push(message) if yield(message) }
				else
					subscribe(symbol, priority) { |l, message| queue.push(message) }
				end
				queue.extend Filter
				queue.listener = listener
				queue
			end

			# Performs a WHOIS command and returns a SilverPlatter::IRC::Whois Struct.
			def whois(user)
				nick	= strip_user_prefixes(user.to_s)
				raise ArgumentError, "Invalid nick #{nick.inspect}" unless valid_nickname?(nick)
				whois	= Whois.new
				whois.exists = true

				@mutex_whois.synchronize do
					subscriptions = [
						subscribe_once(:RPL_WHOISUSER, 10) { |l,m|
							whois.nick       = message.nick
							whois.user       = message.user
							whois.host       = message.host
							whois.real       = message.real
						},
						subscribe_once(:RPL_WHOISSERVER, 10) { |l,m|
							# FIXME, why is there no code?
						},
						subscribe_once(:RPL_WHOISIDLE, 10) { |l,m|
							whois.signon	   = message.signon_time
							whois.idle		   = message.seconds_idle
						},
						subscribe_once(:RPL_UNIQOPIS, 10) { |l,m|
							# FIXME, why is there no code?
						},
						subscribe_once(:RPL_WHOISCHANNELS, 10) { |l,m|
							whois.channels   = message.channels
						},
						subscribe_once(:RPL_IDENTIFIED_TO_SERVICES, 10) { |l,m|
							# FIXME, why is there no code?
						},
						subscribe_once(:ERR_NOSUCHNICK, 10) { |l,m|
							whois.exists = false
						},
						subscribe_once(:RPL_REGISTERED_INFO, 10) { |l,m|
							whois.registered = true
						}
					]
	
					prepare do
						@irc.whois(nick)
					end.wait_for(:RPL_ENDOFWHOIS)
					subscriptions.each { |listener| listener.unsubscribe }
				end

				whois
			end

			def chanlist
			end

			def banlist(channel)
			end

			def terminate(stop_reading=true)
			end
			
			# Read the next message from the server. Returns a
			# SilverPlatter::IRC::Message or nil on disconnect.
			# Does NOT dispatch.
			def read_message
				string = read
				string && @parser.server_message(string)
			end

			# Reads as long as the connection is up, dispatches the read messages
			# Rescues any exception but Interrupt and logs it as exception
			def read_loop
				while string = read
					begin
						message = @parser.server_message(string)
						@subscriptions.each_for(message.symbol) { |listener|
							listener.call(message)
						}
						yield(message) if block_given?
					rescue Interrupt, Errno::EPIPE
						raise
					rescue Exception => e
						exception(e)
					end
				end
			end
			
			def run(&block)
				if block then
					read_loop(&block)
				elsif @read_thread.alive? then
					raise "Already running"
				else
					@read_thread = Thread.new { read_loop }
				end
			end

			# This method is intended for developer use only, it will remove a user from
			# a channel and the channel from the user
			def leave_channel(message, reason1, reason2) # :nodoc:
				if message.from && message.channel then
					message.from.delete_channel(message.channel, reason1)
					message.channel.delete_user(message.from, reason1)
					if message.from.equal?(@me) then
						@channels.delete(message.channel)
						@users.delete_channel(message.channel, reason2)
					elsif !message.from.common_channels?(@me) then
						if message.from.change_visibility(false) then
						# FIXME: inform UserManager
						end
					end
				else
					debug "Unexpected leave_channel (no from or channel)", nil, :message => message
				end
			end
			
			# This method is intended for developer use only, it will remove a user from
			# all his channels and remove all channels from the user, it also drops the user
			# from the connections userlist.
			def leave_server(message, user, reason1, reason2) # :nodoc:
				if user.equal?(@me) then
					user.delete_user(user, reason2)
					delete_user(user, reason2)
				else
					user.delete_user(user, reason1)
					delete_user(user, reason1)
				end
				user.clear
			end
			
			# See CAPAB-IDENTIFY in the ISUPPORT draft.
			# FIXME comment
			def msg_identify
				@parser.msg_identify
			end
			
			# Test whether a string is a valid channelname
			# === Synopsis
			#   connection.valid_channelname?("#silverplatter") # => true
			def valid_channelname?(name)
				name =~ @parser.expression.channel
			end
			
			# Test whether a string is a valid nickname (without prefixes)
			# === Synopsis
			#   connection.valid_nickname?("butler") # => true
			#   connection.valid_nickname?("@butler") # => false
			def valid_nickname?(name)
				name =~ @parser.expressions.nick
			end
			
			# Define which casemapping this connection uses
			def use_casemapping(type)
				case type
					when "ascii"
						extend ASCII_CaseMapping
					when "rfc1459"
						extend RFC1459_CaseMapping
					when "rfc1459-strict"
						extend RFC1459Strict_CaseMapping
					else
						extend RFC1459_CaseMapping
						raise ArgumentError, "Unknown casemapping '#{type}'"
				end
			end
			
			def update_user_unsynchronized(user_obj, nick, user=nil, host=nil, real=nil) # nicklist, userlist
				old_compare = user_obj.compare
				user_obj.update(nick, user, host, real)
				if old_compare != user_obj.compare then
					@nicknames[user_obj.compare] = user_obj
					@nicknames.delete(old_compare)
				end
			end
		end # Connection
	end # IRC
end # SilverPlatter
