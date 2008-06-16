= README for SilverPlatter::IRC

== Indexing
* Author:  Stefan Rusterholz <apeiros@gmx.net>
* Version: 1.0.0
* Website: http://silverplatter.rubyforge.org

== About
SilverPlatter::IRC is an easy to use library for IRC clients. For an example use
take a look at the butler project: http://butler.rubyforge.org which uses it to
implement an IRC bot.

== Installing
=== Via RubyGems
	gem install silverplatter_irc
	sudo botcontrol setup

=== From SVN
	svn checkout svn://rubyforge.org/var/svn/silverplatter/irc/trunk
	cd trunk
	sudo rake install_gem

Notice, if checkout fails, try a few minutes later. Rubyforge drops anonymous svn connections on
higher load.

== Synopsis

== Design
SilverPlatter::IRC is designed in layers, the following layers exist:
* Socket: consists of irc/socket.rb only, it works independently
* Connection: consists of irc/connection.rb and depends on:
	* Socket: see above
	* Channel: represents a single channel Connection knows of
	* ChannelList: a list of channels (e.g. a user is known to be in)
	* Message: a higher representation of a single server message with proper methods
	* Parser: converts the messages of the server into 
	* User: represents a single user Connection knows of
	* UserList
* Client: deals with multiple connections
	* Connection

Socket only provides the simplemost functionality and is "dumb" by design (no automatisms).
Connection is sufficient to build a client allowing a connection to a single server at a
time and is semi-intelligent as Parser, Channel and Users are tied to the connection and
automatically updated apropriatly. Also it can properly deal with requests with multiple
commands as reply, collecting those and making them accessible in a nice format.
Client improves further on that as it can have multiple connections, deals with pings
and provides nice mechanisms to get messages dispatched to methods.
	

== Links
* SilverPlatter-IRCs home: http://silverplatter.rubyforge.org/irc
* The project site: http://rubyforge.org/projects/silverplatter