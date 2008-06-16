#--
# Copyright 2007 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'iconv'



module SilverPlatter
	module IRC
	
		# == Indexing
		# * Author:   Stefan Rusterholz
		# * Contact:  apeiros@gmx.net>
		# * Revision: $Revision: 126 $
		# * Date:     $Date: 2008-03-09 02:33:43 +0100 (Sun, 09 Mar 2008) $
		#
		# == About
		# Represents a message comming from the server. Is created by IRC::Parser.
		#
		# == Synopsis
		# 
		# == Description
		# SilverPlatter::IRC::Message represents messages received by the server.
		# It provides convenience methods that allow to access information about
		# those messages easier, e.g. who (as SilverPlatter::IRC::User object) sent
		# the message in which channel (SilverPlatter::IRC::Channel object) with what
		# text.
		# Raw message and raw parsed data are still available too.
		# Don't create SilverPlatter::IRC::Message manually, leave that up to
		# SilverPlatter::IRC::Connection (which uses SilverPlatter::IRC::Parser to do so)
		#
		# == Notes
		#
		# == Known Bugs
		# Currently none
		# Please inform me about bugs using the bugtracker on
		# http://rubyforge.org/tracker/?atid=17330&group_id=4522&func=browse
		#
		# == See Also
		# * SilverPlatter::IRC
		# * SilverPlatter::IRC::Connection
		# * SilverPlatter::IRC::Parser
		class Message
			# the command-symbol, see COMMANDS (e.g. :PRIVMSG, :JOIN, ...)
			attr_reader :symbol
	
			# a string containing the raw message as received
			attr_reader :raw
	
			# the prefix, normally either the sending user or your irc-server
			attr_reader :prefix

			# the raw command (e.g. "352", "notice", ...)
			attr_reader :command

			# the parameter part
			attr_reader :params

			# the connection this message is tied to
			attr_reader :connection

			# The Butler::IRC::User the message is from.
			attr_reader :from

			# The Butler::IRC::User or Butler::IRC::Channel this message is for. If it's a User, it is
			# most likely Butler::IRC::Client#myself.
			attr_reader :recipient

			# If the message was sent for/in a channel, this will be a Butler::IRC::Channel the message
			# was sent for.
			attr_reader :channel

			# Messages with text will use this attribute to store it. Prominent examples are:
			# * :PRIVMSG - the message
			# * :NOTICE - the message
			# * :PART - part-reason
			# * :QUIT - quit-reason
			# * :KICK - kick-reason
			# * :TOPIC - the new topic
			attr_reader :text
			
			# If the server supports CAPAB IDENTIFY-MSG (informs irc clients whether the user sending a
			# PRIVMSG/NOTICE is identified by nickserv), this method will tell you its value,
			# returns true for messages prefixed with +, false for -, nil if not supported/activated.
			attr_reader :identified
			alias identified? identified
			
			# A hash with additional (custom) fields
			attr_reader :data
			
			
			def initialize(symbol, raw, prefix, command, params, fields, connection=nil) # :nodoc:
				@connection = connection
	
				#raw message
				@raw        = raw
	
				#parsed data
				@prefix     = prefix
				@command    = command
				@params     = params
				@symbol     = symbol

				@from       = nil
				@recipient  = nil
				@channel    = nil
				@text       = nil
				@identified = nil
	
				#specific data
				@data       = fields
			end
	
			def initialize_copy(original) #:nodoc:
				super
				@data = original.data.dup
			end
			
			# Add fiels to this message
			def add_fields(hash)
				@data.merge!(hash)
			end
			
			# Answer a message in kind.
			# * :NOTICE:  If the notice was sent to a channel, it will send a notice to the same channel,
			#             if it was for a user, it will send a notice back to the sender
			# * :PRIVMSG: If the privmsg was sent to a channel, it will send a privmsg to the same channel,
			#             if it was for a user, it will send a privmsg back to the sender
			# * All others: It will send a message to the channel the message was sent to.
			def answer(text)
				raise "Can't answer a #{@symbol} message." unless @channel
				@connection.send_privmsg(text, @channel)
			end
			
			# Access custom fields
			def [](index)
				@data[index]
			end
	
			# Set custom fields
			def []=(index, value)
				@data[index] = value
			end
			
			# Test for presence of a custom field
			def has_key?(key)
				@data.has_key?(key.to_sym)
			end
			
			# Possible realms are:
			# * :channel: The message was sent in a channel
			# * :private: The message was sent as PRIVMSG/NOTICE addressed to you directly
			# * :dcc: The message is a DCC message
			# Notice that a client could add own realms (e.g. Butler uses :remote to indicate
			# messages sent to its built-in Telnet server)
			def realm
				@channel ? :channel : :private
			end

			# True if the message can be seen by more than just the receiver (as in: is sent to a channel)
			def public?
				@channel.nil?
			end

			# True if the message can only be seen by the receiver (as in: is not sent to a channel)
			def private?
				!@channel
			end

			# Change charset encoding
			def transcode!(from, to)
				@text = Iconv.iconv(@text, to, from) unless to.downcase == from.downcase
			end
			
			# Case equality of a message
			# If compared to a symbol, it will compare to the message symbol
			# If compared to a regexp, it will compare the text to that regexp
			# If compared to anything else, it will fail (raise a TypeError)
			def ===(other)
				case other
					when Symbol: @symbol == other
					when Regexp: @text && @text =~ other
					else raise TypeError, "Can't compare #{self} with #{other}"
				end
			end
	
			# return a hash of the fields
			def to_hash
				@data.merge({
					:connection => @connection,
					:raw        => @raw,
					:prefix     => @prefix,
					:command    => @command,
					:params     => @params,
					:symbol     => @symbol,
					:from       => @from,
					:recipient  => @recipient,
					:channel    => @channel,
					:text       => @text,
					:identified => @identified,
				})
			end
			
			def inspect #:nodoc:
				fields = @data.select { |k,v| v }.map { |k,v| "#{k}=#{v}" }.sort.join(", ")
				comma  = fields.empty? ? "" : ", "
				"#<%s:0x%x %s %s%s%s>" %  [
					self.class,
					object_id<<1,
					@raw.inspect,
					inspect_fields,
					comma,
					fields
				]
			end
			
			def method_missing(m, *args, &block) # :nodoc:
				if args.empty? && @data.has_key?(m) then
					@data[m]
				else
					super
				end
			end
			
			alias to_s inspect
			
			private
			def inspect_fields
				"symbol=#{@symbol}"
			end
		end # Message
	end # IRC
end # SilverPlatter
