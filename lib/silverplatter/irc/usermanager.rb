#--
# Copyright 2007 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module SilverPlatter
	module IRC

		# == Authors
		# * Stefan Rusterholz <apeiros@gmx.net>
		#
		# == About
		# UserManager takes care of deleting users gone out of sight for too long
		# 
		# == Synopsis
		#   usermanager = UserManager.new(userlist, max_size, max_age)
		#   usermanager.offline(user) # automatically deletes users from userlist if necessary
		#   usermanager.wipe # explicitly tell usermanager to wipe users from userlist if necessary
		# 
		# == Known Bugs
		# Currently none
		# Please inform me about bugs using the bugtracker on
		# http://rubyforge.org/tracker/?atid=17330&group_id=4522&func=browse
		#
		# == See Also
		# * SilverPlatter::IRC
		# * SilverPlatter::IRC::Connection
		# * SilverPlatter::IRC::UserList
		#
		class UserManager
			# Create a new usermanager
			# Requires a UserList as first argument, the maximum number of users the backlog
			# should have (contains out_of_sight and offline users) and how long their status
			# may maximally be out_of_sight or offline.
			def initialize(connection, userlist, maxsize=8192, maxage=3*3600)
				@connection = connection
				@userlist   = userlist
				@maxsize    = maxsize
				@eliminate  = (1..[maxsize>>5, 4].max) # eliminate a lot at once
				@maxage     = maxage
			end
			
			# Inform Usermanager that a User has changed his status to out_of_sight
			def out_of_sight(user)
				@queue << user
				wipe
			end
			
			# Inform Usermanager that a User has changed his status to offline
			def offline(user)
				@queue << user
				wipe
			end
			
			# Inform Usermanager that a User has changed his status to online
			def into_sight(user)
				@queue.delete(user)
			end
			
			# Remove users from the userlist that are either too old or crossing the threshold
			def wipe
				if @queue.size >= @maxsize then
					for i in @eliminate
						@connection.delete_user(@queue.shift)
					end
				else
					now = Time.now
					while user = queue.first
						unless (age = user.out_of_sight_since || user.offline_since)
							queue.shift
							next
						end
						break if age-now < @maxage
						@connection.delete_user(queue.shift)
					end
				end
			end
		end # UserManager
	end # IRC
end # SilverPlatter
