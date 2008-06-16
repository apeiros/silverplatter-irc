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

		# == Indexing
		# * Author:   Stefan Rusterholz
		# * Contact:  apeiros@gmx.net
		# * Revision: $Revision: 109 $
		# * Date:     $Date: 2008-03-06 11:59:38 +0100 (Thu, 06 Mar 2008) $
		#
		# == About
		# Parse messages from the server to SilverPlatter::IRC::Message.
		# 
		# == Synopsis
		# 
		# == Description
		# Parses messages, automatically converts 
		# provides a parser that automatically connects users and channels
		# regarding who myself is (out_of_sight, back_in_sight for users)
		# allows creation of dialogs from privmsg and notice messages
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
		class Parser

			# enables chdirs, path to the command-sets
			BasePath = (File.expand_path(File.dirname(__FILE__))+'/parser').freeze
			
			# Raised if the parameter part of a message could not be matched.
			class MatchingFailure < RuntimeError
				def initialize(symbol, params)
					super("Matching failed in #{symbol} for #{params.inspect}")
				end
			end
			
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
	
			def initialize(connection, *command_sets)
				@connection   = connection
				@msg_identify = false
				@command_sets = command_sets
				@isupport     = OpenStruct.new(
					:nicklen         => 8,
					:channellen      => 50,
					:prefixes        => "@+",
					:channelprefixes => "\#+&!" # FIXME lookup the correct name, adapt expressions accordingly
				)
				reset
			end

			# Reset the parser using the provided isupport data (if set to nil, it will keep the current
			# isupport data).
			def reset(with_isupport=nil)
				@isupport   = OpenStruct.new(with_isupport) if with_isupport
				@expression = OpenStruct.new
				@commands   = Hash.new { |h,k| raise IndexError, "Unknown command #{k}" }
				
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
				@loading = nil

				@simple_message  = /\A(?::([^ \0]+) )?([A-Za-z\d]+|\d{3})(?: (.*))?\z/
				@simple_hostmask = /(#{expression.nick})(?:(?:!(#{expression.user}))?@(#{expression.host}))?/
				
				@expression.simple_message  = @simple_message
				@expression.simple_hostmask = @simple_hostmask
			end

			def load(*files)
				raise ArgumentError, "Requires at least one argument." if files.empty?
				@command_sets.concat(files.map { |name| name.downcase })
				reset
			end
			
			# Add an expression to the parser, can be used via parser.expression.<name>
			# You can only add an expression with a name that isn't yet added, if you want to change an
			# existing expression you MUST use alter_expression instead. This is to avoid mistakes.
			def add_expression(name, value)
				if @loading[:firstrun] then
					raise "Expression #{name} already added, did you want alter_expression?" if @expression[name]
					@expression[name] = value
				else
					case @loading[:status][name]
						when nil
							@expression[name] = value
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
					raise "Expression #{name} not yet added, did you want add_expression?" unless @expression[name]
					@expression[name] = value
				else
					case @loading[:status][name]
						when nil
							@expression[name] = value
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
				raise IndexError, "Command #{raw} is already registered. Did you want 'alter'?" if @commands.has_key?(raw)
				@commands[raw.downcase] = Command.new(raw, *args, &proc)
			end

			# Alter an existing command
			# You must not use alter to add a new command, use add for this.
			def alter(raw, *args, &proc)
				raise IndexError, "Command #{raw} is not registered. Did you want 'add'?" unless @commands.has_key?(raw)
				@commands[raw.downcase] = Command.new(raw, *args, &proc)
			end
			
			def inspect # :nodoc:
				"#<%s:0x%x %s>" %  [self.class, object_id, @command_sets.join(', ')]
			end

			# parses an incomming message and returns a Message object from which you
			# can easily access parsed data.
			# Expects the newlines to be already chomped off.
			# Process a message and set the additional fields
			# process can have side-effects on the associated Connection
			# FIXME fix documentation of this method
			def server_message(raw)
				prefix, command, params, symbol, from = nil
				from, recipient, channel, text, identified = nil

				# Basic analysis of the message
				raise InvalidMessageFormat, raw unless matched = raw =~ @simple_message
				prefix  = $1
				command = $2
				params	= $3
				command.downcase!

				# Parse prefix if possible (<nick>!<user>@<host>)
				from	= @connection.create_user($1, $2, $3) if prefix and prefix =~ @simple_hostmask

				# in depth analyzis of the message
				processor = @commands[command.downcase]
				symbol    = processor.symbol
				fields    = {}
				if matcher = processor.matcher then
					if match = matcher.match(params) then
						processor.mapping.zip(match.captures) { |name, value| fields[name] = value }
					else
						raise MatchingFailure.new(symbol, params)
					end
				end

				channel   = fields.delete(:channel)
				recipient = fields.delete(:recipient)

				if recipient && @connection.valid_channelname?(recipient) then
					channel   = @connection.create_channel(recipient)
					recipient = channel
				else
					recipient = @connection.create_user(recipient) if recipient
					channel   = @connection.create_channel(channel) if channel
				end
				
				klass     = Message.const_get(symbol) || Message
				message	  = klass.new(@connection, symbol, raw, prefix, command, params, fields)
				processor.processor.call(connection, message)

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
