# Enable running the examples without installation
libdir = File.expand_path(File.dirname(__FILE__)+'/../lib')
$LOAD_PATH.unshift libdir if File.exist?(libdir)

# Require the necessary libraries
require 'rubygems'
require 'silverplatter/irc/connection'

# Who wants to type that everytime? :)
include SilverPlatter

# All methods in the block are provided by SilverPlatter::IRC::ConnectionDSL,
# check there for a complete overview
# Below a client with the more important settings in use
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
	# reconnect_indefinitely # the same as reconnect_tries nil FIXME implement?
	
	# delay the reconnect for so many seconds
	reconnect_delay 60

	# on_nick_error accepts a block that is invoked in case
	# the server informs you that your nick is erroneous or already in use
	on_nick_error &IRC::Connection::IncrementOnNickError

	# on_disconnect accepts a block that is invoked in case the connection is interrupted
	# since termination of the connection can happen for various reasons, the reason is provided
	# and either FIXME.
	on_disconnect { |connection, reason|
		puts "Disconnected due to #{reason}"
		IRC::Client::DefaultProc::OnDisconnect.call(client, connection, reason)
	}
end

$VERBOSE = true
Thread.abort_on_exception = true

client.connect # redundant if you call client.login and nothing between
client.login   # logs in and reads all messages until the message is received that indicates that
               # you may send again. You have to either subscribe before login if you want to handle
               # them. Alternatively you can use login_noblock
client.join("#butler-test") # join one or multiple channels
client.send_privmsg "Hello world!", "#butler-test" # send a message to one or many receivers

begin
	# run blocks until the connection is terminated (that is after on_disconnect).
	# until then it reads every message received by the server and yields it.
	# also see connection_dsl_evented.rb
	client.run do |message|
		case message.symbol
			when :PRIVMSG
				puts message # same as: puts message.text
			when :PING
				# you don't have to handle ping as ping is the only command IRC::Connection will automatically
				# react on by sending a PONG back
			else
				p [:unhandled, message]
		end
	end
rescue Interrupt
	client.quit("demo terminated")
end
puts
puts "Terminated."
