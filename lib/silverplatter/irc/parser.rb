#--
# Copyright 2007 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'ruby/ostruct'
require 'silverplatter/irc/channellist'
require 'silverplatter/irc/hostmask'
require 'silverplatter/irc/message'
require 'silverplatter/irc/parser/command'
require 'silverplatter/irc/string'
require 'silverplatter/irc/userlist'
require 'ruby/exception/detailed'



module SilverPlatter
	module IRC

		# == Authors
		# * Stefan Rusterholz <apeiros@gmx.net>
		#
		# == About
		# Parse messages from the server to SilverPlatter::IRC::Message.
		# 
		# == Synopsis
		# 
		# == Description
		# Parses messages, automatically converts 
		# provides a parser that automatically connects users and channels, puts them in relation to
		# the clients 'me', manages visibility of users and retrieves more information as required.
		# 
		# == Notes
		# Parser is +unsynchronized+. This only plays a role regarding Parser#load.
		# If Parser#load is called while Parser#server_message is used, then the behaviour
		# is unpredictable. If you are in a situation where that may happen, synchronize
		# #reset and #server_message with the same mutex.
		#
		# == Known Bugs
		# Currently none
		# Please inform me about bugs using the bugtracker on
		# http://rubyforge.org/tracker/?atid=17330&group_id=4522&func=browse
		#
		# == See Also
		# * SilverPlatter::IRC
		# * SilverPlatter::IRC::Connection
		#
		class Parser
		
			# The regex used to scan the params
			ParamScanRegex = /[^\x00\x20\r\n:][^\x00\x20\r\n]*|:[^\x00\r\n]*/

			# enables chdirs, path to the command-sets
			BasePath = (File.expand_path(File.dirname(__FILE__))+'/parser').freeze
			
			# Raised if a message that doesn't follow rfc2812 is tried to be parsed.
			class InvalidMessageFormat < RuntimeError; end
			
			# Raised if the parser is given an unknown command to parse.
			class UnknownCommand < RuntimeError; end

			# The parser will extend any unexpected exception with this module and raise it up.
			module ParseError
				include Exception::Detailed

				def self.extended(obj)
					obj.initialize_details
				end
			end
	
			# The connection this parser is tied to, commands will get yielded this connection
			attr_reader :connection
			
			# The commands this parser knows about
			attr_reader :commands
			
			# The (regular) expressions this parser knows about
			attr_reader :expression
			
			# The isupport as given by the server (or defaults otherwise)
			attr_reader :isupport

			# Filter the msg_identify prefix?
			attr_accessor :msg_identify
	
			# This two are only used during #reset
			attr_reader :new_commands, :new_expression # :nodoc:

			# Create a parser for the given connection with the supplied command sets
			# Usually you'll want to load the parser with "rfc2812" and "generic"
			# Notice that load order is important.
			#
			# If you use SilverPlatter::IRC::Connection or Client you will never have
			# direct contact with Parser.
			#
			# = Synopsis
			#   parser = SilverPlatter::IRC::Parser.new(connection, "rfc2812")
			def initialize(connection, *command_sets)
				@connection   = connection
				@msg_identify = false
				@command_sets = command_sets
				@isupport     = OpenStruct.new(
					:nicklen         => 9,      # RFC2812, Section 1.2.2 "Services"
					:channellen      => 50,     # RFC2812, Section 1.3 "Channels"
					:prefixes        => "@+",   # RFC2812, Section 5.1 "Command responses" (319, 352)
					:channelprefixes => "\#+&!" # RFC2812, Section 1.3 "Channels"
				)
				reset
			end

			# Reset the parser using the provided isupport data (if set to nil, it will keep the current
			# isupport data).
			def reset(with_isupport=nil) # :nodoc:
				@isupport   = OpenStruct.new(with_isupport) if with_isupport
				@new_expression = OpenStruct.new
				@new_commands   = Hash.new { |h,k| raise IndexError, "Unknown command #{k}" }
				
				@loading    = {:status => {}, :firstrun => true}

				expressions = []
				commands    = []
				@command_sets.each { |name|
					dir = name.include?('/') ? name : "#{BasePath}/#{name}"
					exp = "#{dir}/expressions.rb"
					com = "#{dir}/commands.rb"
					expressions << exp if File.exist?(exp)
					commands    << com if File.exist?(com)
				}
				
				# load the expressions
				# expression loading happens twice, once in order as given to enable definition based on other expressions,
				# once in reverse to redefine those that are defined by others that were updated in a following file
				# example: there are many patterns that require the 'nick' expression which is often altered, so to avoid
				# that you have to redefine all altered expressions too, the files are loaded in reverse after so the patterns
				# depending on nick are redefined accordingly. patterns that have a newer definition are ignored.
				# takes precedence and less specific ones can be ignored
				expressions.each { |expfile|
					instance_eval(File.read(expfile), expfile)
				}
				@loading[:firstrun] = false
				expressions.reverse_each { |expfile|
					instance_eval(File.read(expfile), expfile)
				}
				
				# load the commands
				commands.each { |comfile|
					instance_eval(File.read(comfile), comfile)
				}
				@loading        = nil
				@message_regex  = @new_expression.message # performance
				@expression     = @new_expression
				@commands       = @new_commands
				@new_expression = nil
				@new_commands   = nil
				self
			end

			# Load additional command-sets.
			def load(*files)
				raise ArgumentError, "Requires at least one argument." if files.empty?
				@command_sets.concat(files.map { |name| name.downcase })
				reset
			end
			
			# Add an expression to the parser, can be used via parser.expression.<name>
			# You can only add an expression with a name that isn't yet added, if you want to change an
			# existing expression you MUST use alter_expression instead. This is to avoid mistakes.
			def add_expression(name, value)
				if @loading[:firstrun] then
					raise "Expression #{name} already added, did you want alter_expression?" if @new_expression[name]
					@new_expression[name] = value
				else
					case @loading[:status][name]
						when nil
							@new_expression[name] = value
						when :added # should never happen
							raise "Expression #{name} already added, did you want alter_expression?"
						when :altered # ignore
					end
					@loading[:status][name] = :added
				end
			end
			
			# Alter an existing expression. If another file defines an expression beforehand, you have to use
			# alter_expression instead of add_expression
			def alter_expression(name, value)
				if @loading[:firstrun] then
					raise "Expression #{name} not yet added, did you want add_expression?" unless @new_expression[name]
					@new_expression[name] = value
				else
					case @loading[:status][name]
						when nil
							@new_expression[name] = value
						when :added # should never happen
							raise "Expression #{name} alteration prior to adding"
						when :altered # ignore, newer altered takes precedence
					end
					@loading[:status][name] = :altered
				end
			end
			
			# Add a new command
			# You must not use add to change an existing command, use alter for this.
			def add(raw, *args, &proc)
				raise IndexError, "Command #{raw} is already registered. Did you want 'alter'?" if @new_commands.has_key?(raw)
				@new_commands[raw.downcase] = Command.new(raw, *args, &proc)
			end

			# Alter an existing command
			# You must not use alter to add a new command, use add for this.
			def alter(raw, *args, &proc)
				raise IndexError, "Command #{raw} is not registered. Did you want 'add'?" unless @new_commands.has_key?(raw)
				@new_commands[raw.downcase] = Command.new(raw, *args, &proc)
			end
			
			def inspect # :nodoc:
				sprintf "#<%s:0x%x %s>",
					self.class,
					object_id<<1,
					@command_sets.join(', ')
				# /sprintf
			end

			# parses an incomming message and returns a Message object from which you
			# can easily access parsed data.
			# Expects the newlines to be already chomped off.
			# Process a message and set the additional fields
			# process can have side-effects on the associated Connection
			#
			# == Notes
			# There are several 'magic' fields which the parser will automatically convert:
			# * :channel - will automatically be replaced by the corresponding Channel object (by name)
			# * :recipient - will automatically be replaced by the corresponding User object (by nick)
			#
			# == FIXME
			# * documentation of this method
			def server_message(raw)
				prefix, command, params, symbol, from = nil
				from, recipient, channel, text, identified = nil

				# Basic analysis of the message
				#raise InvalidMessageFormat, raw unless matched = raw =~ @simple_message
				raise InvalidMessageFormat, raw unless matched = raw.match(@message_regex)
				# $1: prefix, $2: hostname, $3: nick, $4: user, $5: host, $6: command, $7: params
				prefix, servername, nick, user, real, command, params = *matched.captures
				from    = @connection.create_user(nick, user, real) if nick
				params  = params ? params.scan(ParamScanRegex) : []
				params.last.sub!(/^:/, '') if params.last
				command.downcase!

				# in depth analyzis of the message
				processor = @commands[command.downcase]
				symbol    = processor.symbol
				
				fields    = {}
				processor.mapping.zip(params) { |name, value| fields[name] = value }

				channel   = fields.delete(:channel)
				recipient = fields.delete(:recipient)

				if recipient && @connection.valid_channelname?(recipient) then
					channel   = @connection.create_channel(recipient)
					recipient = channel
				else
					recipient = @connection.create_user(recipient) if recipient
					channel   = @connection.create_channel(channel) if channel
				end
				
				klass     = Message.const_defined?(symbol) ? Message.const_get(symbol) : Message
				message	  = klass.new(symbol, raw, prefix, command, params, fields, @connection)
				message.instance_eval {
					@from       = from
					@recipient  = recipient
					@channel    = channel
					@text       = fields.delete(:text)
					@identified = nil
				}
				processor.processor.call(connection, message, fields) if processor.processor

				message
			rescue IndexError
				raise UnknownCommand, "Unknown command #{command}: #{raw.inspect}"
			rescue => e
				e.extend ParseError
				e.prepend "Message: #{raw.inspect}"
				raise e
			end
		end # Parser
	end # IRC
end # SilverPlatter
