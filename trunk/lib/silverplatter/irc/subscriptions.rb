#--
# Copyright 2007 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'thread'



module SilverPlatter
	module IRC

		# == Indexing
		# * Author:   Stefan Rusterholz
		# * Contact:  apeiros@gmx.net>
		# * Revision: $Revision: 141 $
		# * Date:     $Date: 2008-03-14 17:48:39 +0100 (Fri, 14 Mar 2008) $
		#
		# == About
		# Subscriptions manages a set of listeners for a connection. It deals with subscribing,
		# priority and unsubscribing.
		#
		# == Synopsis
		#   include SilverPlatter::IRC
		#   subscriptions = Subscriptions.new
		#   listener      = Listener.new(:foo) { do_stuff }
		#   subscriptions.subscribe(listener)
		#   subscriptions.each_for(:foo) { |listener| ... }
		#   subscriptions.unsubscribe(listener) # or: listener.unsubscribe
		# 
		# == Known Bugs
		# Currently none
		# Please inform me about bugs using the bugtracker on
		# http://rubyforge.org/tracker/?atid=17330&group_id=4522&func=browse
		#
		# == See Also
		# * SilverPlatter::IRC
		# * SilverPlatter::IRC::Listener
		# * SilverPlatter::IRC::Connection
		class Subscriptions
			include Enumerable

			attr_reader :mutex

			def initialize
				@mutex      = Mutex.new
				@all        = {} # subscription => true
				@per_symbol = Hash.new { |h,k| h[k] = [] } # symbol => subscription (nil = all symbols)
			end
			
			# Iterate over all listeners in this Subscriptions list
			def each(&block)
				@all.each_key(&block)
				self
			end
			
			# Iterate over all listeners for the given symbol in this Subscriptions list
			# returns an array if no block is provided
			# Listeners explicitly registered for a symbol take precedence over generic listeners
			def each_for(symbol, &block)
				if block then
					@per_symbol[symbol].each(&block)
					@per_symbol[nil].each(&block)
					self
				else
					@per_symbol[symbol] + @per_symbol[nil]
				end
			end
			
			# Add a listener to this list of subscriptions
			def subscribe(listener)
				@mutex.synchronize {
					raise "#{listener} already subscribed" if @all[listener]
					listener.container = self
					@all[listener]     = true
					listener.each { |s|
						@per_symbol[s] << listener
						@per_symbol[s] = @per_symbol[s].sort_by { |l| -l.priority }
					}
				}
				true
			end
			
			# Remove a listener from this list of subscriptions
			def unsubscribe(listener)
				@mutex.synchronize {
					@all.delete(listener)
					listener.each { |s|
						@per_symbol[s].delete(listener)
						@per_symbol.delete(s) if @per_symbol[s].empty?
					}
				}
			end
			
			# Reflect a mutation of a listener (change of priority)
			def mutated(listener)
				@mutex.synchronize {
					listener.each { |symbol|
						@per_symbol[s] = @per_symbol[s].sort_by { |l| -l.priority }
					}
				}
			end
		end
	end
end
