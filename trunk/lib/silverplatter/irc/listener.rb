#--
# Copyright 2007 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module SilverPlatter
	module IRC

		# == Indexing
		# * Author:   Stefan Rusterholz
		# * Contact:  apeiros@gmx.net>
		# * Revision: $Revision: 129 $
		# * Date:     $Date: 2008-03-09 15:52:04 +0100 (Sun, 09 Mar 2008) $
		#
		# == About
		#
		# == Synopsis
		#   listener = Listener.new(:foo, 3, "permanent argument") { do_stuff }
		# 
		# == Notes
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
		# * SilverPlatter::IRC::Subscriptions
		# * SilverPlatter::IRC::Connection
		# * SilverPlatter::IRC::Connection#subscribe
		class Listener
			AllSymbols = [nil].freeze
			include Comparable
			include Enumerable

			# The priority of this listener, higher value means earlier execution
			attr_reader   :priority
			
			# The symbols this listener is registered for
			attr_reader   :symbols
			
			# The Subscriptions object this listener is tied to
			attr_accessor :container

			# Create a Listener instance
			# * symbols: nil, a single Symbol or an Array thereof, determines on which the listener should be invoked
			# * priority: The priority with which this listener should be treated. Higher priority comes first.
			# * args: Are always appended as arguments on calling this listener
			# Nil as symbol means that the listener is invoked on *all* symbols.
			def initialize(symbols=nil, priority=0, *args, &callback)
				@priority  = priority || 0
				@symbols   = (symbols ? Array(symbols) : AllSymbols).freeze
				if @symbols.include?(nil) && @symbols.length > 1 then
					raise "You must not register to all symbols and specific symbols at the same time"
				elsif @symbols.empty? then
					raise "You must register to at least one symbol"
				end
				@args      = args
				@callback  = callback
				@container = nil
			end
			
			# Iterate over all symbols this listener is subscribed to
			def each(&block)
				@symbols.each(&block)
			end

			# Will remove this listener from the clients dispatcher forever
			def unsubscribe
				@container.unsubscribe(self)
			end

			# Comparison is done by priority, higher priority comes first, so
			# Listener.new(nil, -100) > Listener.new(nil, 100)
			def <=>(other)
				other.priority <=> @priority
			end

			# Set the priority of this listener
			# See SilverPlatter::IRC::Connection#subscribe() for infos about priority
			def priority=(value)
				@priority = Integer(value)
				@container.mutated(self)
			end
			
			# Invoke the listener, always passes self as first argument
			def call(*args)
				@callback.call(self, *(args+@args))
			end
		end # Listener
	end # IRC
end # SilverPlatter
