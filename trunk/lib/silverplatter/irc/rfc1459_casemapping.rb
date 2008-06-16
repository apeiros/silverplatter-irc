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
		# SilverPlatter::IRC::RFC1459_CaseMapping provides the casemap method
		# which lowercases a string according to rfc1459 (non strict)
		# 
		# == Synopsis
		#   RFC1459_CaseMapping.casemap(string)
		#   include RFC1459_CaseMapping
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
		module RFC1459_CaseMapping
			# RFC 1459 conform uppercase letters,  used to map cases
			RFC1459_Upper = "A-^".freeze

			# RFC 1459 conform lowercase letters,  used to map cases
			RFC1459_Lower = "a-~".freeze
			
			# Map a string to lowercase according to RFC1459, known in
			# ISUPPORT as rfc1459 (not strict-rfc1459)
			def casemap(string)
				string.tr(RFC1459_Upper, RFC1459_Lower)
			end
		end
	end
end
