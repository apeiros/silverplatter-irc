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
		# * Revision: $Revision: 132 $
		# * Date:     $Date: 2008-03-09 17:42:25 +0100 (Sun, 09 Mar 2008) $
		#
		# == About
		# SilverPlatter::IRC::ASCII_CaseMapping provides the casemap method
		# which lowercases a string according to ascii
		# 
		# == Synopsis
		#   ASCII_CaseMapping.casemap(string)
		#   include ASCII_CaseMapping
		#   casemap(string)
		# 
		# == Known Bugs
		# Currently none.
		# Please inform me about bugs using the bugtracker on
		# http://rubyforge.org/tracker/?atid=17330&group_id=4522&func=browse
		#
		# == See Also
		# * SilverPlatter::IRC
		# * http://www.faqs.org/ftp/internet-drafts/draft-brocklesby-irc-isupport-03.txt
		#   section 3.1
		module ASCII_CaseMapping
			# RFC 1459 conform uppercase letters, used to map cases
			ASCII_Upper = "A-Z".freeze

			# RFC 1459 conform lowercase letters, used to map cases
			ASCII_Lower = "a-z".freeze
			
			# Map a string to lowercase according to RFC1459, known in
			# ISUPPORT as ascii
			def casemap(string)
				string.tr(ASCII_Upper, ASCII_Lower) # sometime in future maybe
				# string.downcase # slower than tr?!?
			end
			module_function :casemap
		end
	end
end
