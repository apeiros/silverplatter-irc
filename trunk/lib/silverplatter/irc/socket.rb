#--
# Copyright 2007 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'silverplatter/diagnostics'
require 'silverplatter/log/comfort'
require 'socket'
require 'thread'



module SilverPlatter
	module IRC
	
		# == Authors
		# * Stefan Rusterholz <apeiros@gmx.net>
		#
		# ==Description
		# SilverPlatter::IRC::Socket is a TCPSocket, retrofitted for communication
		# with IRC-Servers.
		# It provides specialized methods for sending messages to IRC-Server.
		# All methods are safe to be used with SilverPlatter::IRC::* Objects (e.g. all
		# parameters expecting a nickname will accept an SilverPlatter::IRC::User as well).
		# It will adhere to its limit-settings, which will prevent from sending too
		# many messages in a too short time to avoid excess flooding.
		# SilverPlatter::IRC::Socket#write_with_eol is the only synchronized method, since
		# all other methods build up on it, IRC::Socket should be safe in threaded
		# environments. SilverPlatter::IRC::Socket#read is NOT synchronized, so unless you
		# read from only a single thread, statistics might get messed up.
		# Length limits can only be safely guaranteed by specialized write methods,
		# SilverPlatter::IRC::Socket#read from only will just warn and send the overlength
		# message. If you are looking for queries (commands that get an answer from the
		# server) take a look at SilverPlatter::IRC::Connection.
		# 
		# ==Synopsis
		#   irc = SilverPlatter::IRC::Socket.new('irc.freenode.org', :port => 6667)
		#   irc.connect
		#   irc.login('your_nickname', 'YourUser', 'Your realname')
		#   irc.send_join("#channel3")
		#   irc.send_part("#channel3")
		#   irc.send_privmsg("Hi all of you in #channel1!", "#channel1")
		#   irc.close
		# 
		# ==Notes
		# * Errno::EHOSTUNREACH: server not reached
		# * Errno::ECONNREFUSED: server is up, but refuses connection
		# * Errno::ECONNRESET:   connection works, server did not yet accept connection, resets after
		# * Errno::EPIPE:        writing to a server-side closed connection, nil on gets, connection was terminated
		#
		class Socket
			VERSION	= "1.0.0"

			include Log::Comfort
			include RFC1459_CaseMapping

			# server the instance is linked with
			attr_reader :server

			# port used for connection
			attr_reader :port

			# the own host (nil if not supported)
			attr_reader :host

			# end-of-line used for communication
			attr_reader :eol
	
			# contains counters:
			# *:read_lines
			# *:read_bytes
			# *:sent_lines
			# *:sent_bytes
			attr_reader :count
	
			# contains limits for the protocol, burst times/counts etc.
			attr_reader :limit
			
			# log raw out, will use log_out.puts(raw)
			attr_accessor :log_out
			
			DefaultOptions = {
				:port => 6667,
				:eol  => "\r\n".freeze,
				:host => nil,
			}
			
			# Fix evil behaviour of IO::new (complains if a block is given)
			def self.new(*a, &b) # :nodoc:
				obj = allocate
				obj.send(:initialize, *a, &b)
				obj
			end
			
			# Initialize properties, doesn't connect automatically
			# options:
			# * :server: ip/domain of server (overrides a given server parameter)
			# * :port:   port to connect on, defaults to 6667
			# * :eol:    what character sequence terminates messages, defaults to \r\n
			# * :host:   what host address to bind to, defaults to nil
			#
			def initialize(server, options={})
				options       = DefaultOptions.merge(options)
				@logger       = options.delete(:log)
				@server       = options.delete(:server) || server
				@port         = options.delete(:port)
				@eol          = options.delete(:eol).dup.freeze
				@host         = options[:host] ? options.delete(:host).dup.freeze : options.delete(:host)
				@log_out      = nil
				@last_sent    = Time.new()
				@count        = Hash.new(0)
				@limit        = {
					:message_length => 300, # max. length of a text message (e.g. in notice, privmsg) sent to server
					:raw_length     => 400, # max. length of a raw message sent to server
					:burst          => 4,   # max. messages that can be sent with send_delay (0 = infinite)
					:burst2         => 20,  # max. messages that can be sent with send_delay (0 = infinite)
					:send_delay     => 0.1, # minimum delay between each message
					:burst_delay    => 1.5, # delay after a burst
					:burst2_delay   => 15,  # delay after a burst2
				}
				@limit.each { |key, default|
					@limit[key] = options.delete(key) if options.has_key?(key)
				}
				@mutex        = Mutex.new
				@socket       = Diagnostics.new(self, :write => [NoMethodError, "Must connect first to write to the socket"])
				@connected    = false
				raise ArgumentError, "Unknown arguments: #{options.keys.inspect}" unless options.empty?
			end
			
			# Whether this Socket is currently connected to a server or not.
			def connected?
				@connected
			end

			# connects to the server
			def connect
				info("Connecting to #{@server} on port #{@port} from #{@host || '<default>'}")
				@socket	= TCPSocket.open(@server, @port, @host)
				info("Successfully connected")
			rescue ArgumentError => error
				if @host then
					warn("host-parameter is not supported by your ruby version. Parameter discarted.")
					@host = nil
					retry
				else
					raise
				end
			rescue Interrupt
				raise
			rescue Exception
				error("Connection failed.")
				raise
			else
				@connected		= true
			end
	
			# get next message (eol already chomped) from server, blocking, returns nil if closed
			def read
				if m = @socket.gets(@eol) then
					@count[:read_lines] += 1
					@count[:read_bytes] += m.size
					m.chomp(@eol)
				else
					@connected = false
					nil
				end
			rescue IOError
				@connected = false
				nil
			end
	
			# Send a raw message to irc, eol will be appended
			# Use specialized methods instead if possible since they will releave
			# you from several tasks like translating newlines, take care of overlength
			# messages etc.
			def write_with_eol(data)
				@mutex.synchronize {
					warn("Raw too long (#{data.length} instead of #{@limit[:raw_length]})") if (data.length > @limit[:raw_length])
					now	= Time.now
		
					# keep delay between single (bursted) messages
					sleeptime = @limit[:send_delay]-(now-@last_sent)
					if sleeptime > 0 then
						sleep(sleeptime)
						now += sleeptime
					end
					
					# keep delay after a burst (1)
					if (@count[:burst] >= @limit[:burst]) then
						sleeptime = @limit[:burst_delay]-(now-@last_sent)
						if sleeptime > 0 then
							sleep(sleeptime)
							now += sleeptime
						end
						@count[:burst]	= 0
					end
		
					# keep delay after a burst (2)
					if (@count[:burst2] >= @limit[:burst2]) then
						sleeptime = @limit[:burst2_delay]-(now-@last_sent)
						if sleeptime > 0 then
							sleep(sleeptime)
							now += sleeptime
						end
						@count[:burst2]	= 0
					end
		
					# send data and update data
					@last_sent  = Time.new
					data       += @eol
					@socket.write(data)
					@count[:burst]      += 1
					@count[:burst2]     += 1
					@count[:sent_lines] += 1
					@count[:sent_bytes] += data.length
					@log_out.puts(data) if @log_out
				}
			rescue IOError
				error("Writing #{data.inspect} failed")
				raise
			end 
	
			# log into the irc-server (and connect if necessary)
			def login(nickname, username, realname, serverpass=nil)
				connect unless @connected
				write_with_eol("PASS #{serverpass}") if serverpass
				write_with_eol("NICK #{nickname}")
				write_with_eol("USER #{username} 0 * :#{realname}")
			end
	
			# identify nickname to nickserv
			# FIXME: figure out what the server supports, possibly requires it
			# to be moved to SilverPlatter::IRC::Connection (to allow ghosting, nickchange, identify)
			def send_identify(password)
				write_with_eol("NS :IDENTIFY #{password}")
			end
			
			# FIXME: figure out what the server supports, possibly requires it
			# to be moved to SilverPlatter::IRC::Connection (to allow ghosting, nickchange, identify)
			def send_ghost(nickname, password)
				write_with_eol("NS :GHOST #{nickname} #{password}")
			end
			
			# cuts the message-text into pieces of a maximum size
			# (or until the next newline if shorter)
			def normalize_message(message, limit=nil, &block)
				message.scan(/[^\n\r]{1,#{limit||@limit[:message_length]}}/, &block)
			end
	
			# sends a privmsg to given user or channel (or multiple)
			# messages containing newline or exceeding @limit[:message_length] are automatically splitted
			# into multiple messages.
			def send_privmsg(message, *recipients)
				normalize_message(message) { |message|
					recipients.each { |recipient|
						write_with_eol("PRIVMSG #{recipient} :#{message}")
					}
				}
			end
	
			# same as privmsg except it's formatted for ACTION
			def send_action(message, *recipients)
				normalize_message(message) { |message|
					recipients.each { |recipient|
						write_with_eol("PRIVMSG #{recipient} :\001ACTION #{message}\001")
					}
				}
			end
	
			# sends a notice to receiver (or multiple if receiver is array of receivers)
			# formatted=true allows usage of ![]-format commands (see IRCmessage.getFormatted)
			# messages containing newline automatically get splitted up into multiple messages.
			# Too long messages will be tokenized into fitting sized messages (see @limit[:message_length])
			def send_notice(message, *recipients)
				normalize_message(message) { |message|
					recipients.each { |recipient|
						write_with_eol("NOTICE #{recipient} :#{message}")
					}
				}
			end
	
			# send a pong
			def send_pong(*args)
				if args.empty? then
					write_with_eol("PONG")
				else
					write_with_eol("PONG #{args.join(' ')}")
				end
			end
	
			# join specified channels
			# use an array [channel, password] to join password-protected channels
			# returns the channels joined.
			# ==Synopsis
			#   irc.send_join("#foo", "#bar")
			#   irc.send_join(["#foo", "pass_for_foo"])
			#   require 'silverplatter/irc/string'
			#   irc.send_join("#foo".with_password("foopass"))
			def send_join(*channels)
				channels.map { |channel, password|
					if password then
						write_with_eol("JOIN #{channel} #{password}")
					else
						write_with_eol("JOIN #{channel}")
					end
					channel
				}
			end
	
			# part specified channels
			# returns the channels parted from.
			def send_part(reason=nil, *channels)
				if channels.empty?
					channels = [reason]
					reason   = nil
				end
				reason ||= "leaving"

				# some servers still can't process lists of channels in part
				channels.each { |channel|
					write_with_eol("PART #{channel} #{reason}")
				}
			end
	
			# set your own nick
			# does NO verification/validation of any kind
			def send_nick(nick)
				write_with_eol("NICK #{nick}")
			end
	
			# set your status to away with reason 'reason'
			def send_away(reason="")
				return back if reason.empty?
				write_with_eol("AWAY :#{reason}")
			end
	
			# reset your away status to back
			def send_back
				write_with_eol("AWAY")
			end
	
			# kick user in channel with reason
			def send_kick(user, channel, reason)
				write_with_eol("KICK #{channel} #{user} :#{reason}")
			end
			
			# send a mode command to a channel
			def send_mode(channel, mode=nil)
				write_with_eol(mode ? "MODE #{channel} #{mode}" : "MODE #{channel}")
			end
			
			# Give Op to user in channel
			# User can be a nick or IRC::User, either one or an array.
			# FIXME: check number of targets MODE can take
			def send_multiple_mode(channel, pre, flag, targets)
				(0...targets.length).step(10) { |i|
					slice = targets[i,10]
					write_with_eol("MODE #{channel} +#{flag*slice.length} #{slice*' '}")
				}
			end
	
			# Give Op to user in channel
			# User can be a nick or IRC::User, either one or an array.
			def send_op(channel, *users)
				send_multiple_mode(channel, '+', 'o', users)
			end
	
			# Take Op from user in channel
			# User can be a nick or IRC::User, either one or an array.
			def send_deop(channel, *users)
				send_multiple_mode(channel, '-', 'o', users)
			end
	
			# Give voice to user in channel
			# User can be a nick or IRC::User, either one or an array.
			def send_voice(channel, *users)
				send_multiple_mode(channel, '+', 'v', users)
			end
	
			# Take voice from user in channel.
			# User can be a nick or IRC::User, either one or an array.
			def send_devoice(channel, *users)
				send_multiple_mode(channel, '-', 'v', users)
			end
	
			# Set ban in channel to mask
			def send_ban(channel, *masks)
				send_multiple_mode(channel, '+', 'b', masks)
			end
	
			# Remove ban in channel to mask
			def send_unban(channel, *masks)
				send_multiple_mode(channel, '-', 'b', masks)
			end

			# Send a "who" to channel/user
			def send_who(target)
				write_with_eol("WHO #{target}")
			end
	
			# Send a "whois" to server
			def send_whois(nick)
				write_with_eol("WHOIS #{nick}")
			end
	
			# send the quit message to the server
			def send_quit(reason="leaving")
				write_with_eol("QUIT :#{reason}")
			end
			
			# send the quit message to the server
			# unless you set close to false it will also close the socket
			def quit(reason="leaving", close=true)
				send_quit(reason)
				close() if close
			end
	
			# closes the connection to the irc-server
			def close
				@socket.close
			end
			
			def inspect # :nodoc:
				sprintf "#<%s:0x%08x %s:%s from %s using '%s', stats: %s>",
					self.class,
					object_id<<1,
					@server,
					@port,
					@host || "<default>",
					@eol.inspect[1..-2],
					@count.inspect
				# /sprintf
			end
		end
	end
end
