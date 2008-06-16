#--
# Copyright 2007 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'log/comfort'



module SilverPlatter
	module IRC
		class Parser

			# == Indexing
			# * Author:   Stefan Rusterholz
			# * Contact:  apeiros@gmx.net>
			# * Revision: $Revision$
			# * Date:     $Date$
			#
			# == About
			# Provides parsing information about specific commands.
			#
			# == Synopsis
			# 
			# == Description
			# Members of Command:
			# * raw:       The full string of the command as received from the server
			# * symbol:    The symbol representing the command (e.g. :PRIVMSG)
			# * regex:     The regular expression for the parameter part of the message
			# * mapping:   The fields associated with the regex' captures
			# * processor: A proc to process the message further, possibly having side-effects
			# See Butler::IRC::COMMANDS for samples on instanciation of
			# Butler::IRC::Command objects.
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
			class Command < Struct.new(:raw, :symbol, :regex, :mapping, :processor)
				def initialize(raw, symbol, regex=nil, mapping=nil, &processor)
					super(raw, symbol, regex, mapping, processor)
				end
			end # Command
		end # Parser
	end # IRC
end # SilverPlatter
