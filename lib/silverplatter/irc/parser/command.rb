#--
# Copyright 2007 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'silverplatter/log/comfort'



module SilverPlatter
	module IRC
		class Parser

			# == Authors
			# * Stefan Rusterholz <apeiros@gmx.net>
			#
			# == About
			# Provides parsing information about specific commands.
			#
			# == Synopsis
			# 
			# == Description
			# Members of Command:
			# raw::       The full string of the command as received from the server
			# symbol::    The symbol representing the command (e.g. :PRIVMSG)
			# mapping::   Names for the message's parameters
			# processor:: A proc to process the message further, possibly having side-effects
			#             Like sending who and mode to a channel on join or bookkeeping of
			#             Users and Channels.
			#
			# See SilverPlatter::IRC::COMMANDS for samples on instanciation of
			# SilverPlatter::IRC::Command objects.
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
			# * SilverPlatter::IRC::Parser
			# * SilverPlatter::IRC::Connection
			#
			class Command < Struct.new(:raw, :symbol, :mapping, :processor)
				def initialize(raw, symbol, *mapping, &processor)
					super(raw, symbol, mapping, processor)
				end
			end # Command
		end # Parser
	end # IRC
end # SilverPlatter
