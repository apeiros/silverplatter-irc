#--
# Copyright 2007 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'silverplatter/irc/rfc1459_casemapping.rb'



module SilverPlatter
	module IRC

		# == Indexing
		# * Author:   Stefan Rusterholz
		# * Contact:  apeiros@gmx.net>
		# * Revision: $Revision: 109 $
		# * Date:     $Date: 2008-03-06 11:59:38 +0100 (Thu, 06 Mar 2008) $
		#
		# == About
		# SilverPlatter::IRC::Hostmask provides methods to see if hostmasks match.
		# 
		# == Known Bugs
		# Currently none.
		# Please inform me about bugs using the bugtracker on
		# http://rubyforge.org/tracker/?atid=17330&group_id=4522&func=browse
		#
		# == See Also
		# * SilverPlatter::IRC
		# * SilverPlatter::IRC::Channel
		# * http://www.faqs.org/rfcs/rfc1459.html Section 4.2.3.1
		class Hostmask
			include RFC1459_CaseMapping
			
			# Regex used to split up a stringform hostmask into its parts
			ScanMask = /\A([^!]*)!([^@]*)@(.*)\z/.freeze # :nodoc:

			# Create a hostmask from a hostmask-string, e.g. "nick!user@host.tld"
			# Also see Butler::IRC::User#hostmask
			def self.from_mask(string, connection=nil)
				raise ArgumentError, "Invalid Hostmask '#{string}'" unless match = string.match(ScanMask)
				nick, user, host = *match.captures
				new(nick, user, host, connection)
			end
			
			# Return the stringform of the hostmask, e.g. "nick!user@host.tld"
			attr_reader :hostmask
			alias to_s   hostmask
			alias to_str hostmask
			
			# Return the connection this hostmask uses
			attr_reader :connection
			
			# The regular expression used to match a hostmask
			attr_reader :regex
			
			# The original data [nick, user, host]
			attr_reader :data
			
			# Create a hostmask from nick, user and host
			# example:
			#   Hostmask.new("nick!user@host.tld") # => 
			# Also see Butler::IRC::User#hostmask
			def initialize(nick, user, host, connection=nil)
				@data       = nick, user, host
				@connection = connection
				nick        = casemap(nick)
				@hostmask   = "#{nick}!#{user}@#{host}".freeze
				nick, user, host = *[nick, user, host].map { |part|
					Regexp.escape(part).gsub(/\\\*/, '.*?').gsub(/\\\?/, '.')
				}
				@regex      = /\A(#{nick})!(#{user})@(#{host})\z/.freeze
			end

			# Match a hostmask or anything that responds to #hostmask or #to_str
			# With #hostmask it expects the mask to be properly casemapped to lowercase.
			# Sets $1-$3 to nick, user and host if matched.
			# Notice that if you match a hostmask with wildcards against one without, the one
			# with the wildcards needs to be on the left hand side.
			def =~(mask)
				!! if mask.respond_to?(:hostmask) then
					@regex =~ mask.hostmask.to_str
				else
					@regex =~ mask.to_str.sub(/[^!]*/) { |nick| casemap(nick) }
				end
			end
			alias === =~
			
			# Match a hostmask or anything that responds to #hostmask or #to_str
			# Returns a MatchData instance with 3 captures (nick, user, host)
			def match(mask)
				mask	= mask.hostmask if mask.kind_of?(User)
				@regex.match(mask.to_str)
			end

			def inspect # :nodoc:
				"#<Hostmask #{@mask} (#{@regex.inspect})>"
			end

			private
			def casemap(nick) # :nodoc:
				@connection ? @connection.casemap(nick) : super
			end
		end # Hostmask
	end
end
