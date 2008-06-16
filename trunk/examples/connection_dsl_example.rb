# Enable running the examples without installation
libdir = File.expand_path(File.dirname(__FILE__)+'/../lib')
$LOAD_PATH.unshift libdir if File.exist?(libdir)

# Require the necessary libraries
require 'rubygems'
require 'silverplatter/irc/connection'

# Who wants to type that everytime? :)
include SilverPlatter

client = IRC::Connection.new do
	# server data
	server        "irc.freenode.org"
	port          6667
	serverpass    nil

	# client data
	nickname      "silverp"
	username      "silver"
	realname      "SilverPlatter-IRC"
	
	# pings the server in the given interval
	ping_interval 600
	
	# reconnect so many times on timeouts/sudden disconnects
	reconnect_tries nil # nil means infinite times
	
	# delay the reconnect for so many seconds
	reconnect_delay 60

	# callbacks
	on_nick_err { |client, connection, previous|
		newnick = previous.dup
		newnick.sub!(/^\[(\d+)\]/) { "[#{$1.to_i+1}]" } || newnick.sub!(/^/, '[1]')
		connection.nick(newnick)
	}
	on_disconnect { |client, connection, reason|
		puts "Disconnected due to #{reason}"
		IRC::Client::DefaultProc::OnDisconnect.call(client, connection, reason)
	}
end

client.connect # redundant if you call client.login and nothing between
client.login
client.run do |message|
	case message.symbol
		when :PRIVMSG
			# do something with it
		when :PING
			# you don't have to handle ping as ping is the only command IRC::Client will automatically
			# react on by sending a PONG back
	end
end
