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
		# SilverPlatter::IRC::RFC1459Strict_CaseMapping provides the casemap method
		# which lowercases a string according to strict-rfc1459
		# 
		# == Synopsis
		#   include RFC1459Strict_CaseMapping
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
		#
		module RFC1459Strict_CaseMapping
			# RFC 1459 conform uppercase letters,  used to map cases
			RFC1459Strict_Upper = "A-]".freeze

			# RFC 1459 conform lowercase letters,  used to map cases
			RFC1459Strict_Lower = "a-}".freeze

			# Map a string to lowercase according to RFC1459, known in
			# ISUPPORT as strict-rfc1459
			def casemap(string)
				string.tr(RFC1459_Upper, RFC1459_Lower)
			end
		end
	end
end
