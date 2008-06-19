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
		IRC::Connection::OnDisconnect.call(client, connection, reason)
	}
end

$VERBOSE = true
Thread.abort_on_exception = true

begin
	client.subscribe(:PRIVMSG) { |listener, message| puts "#{message}" }
	client.subscribe { |listener, message| puts "#{message.symbol}: #{message}" }
	client.connect # redundant if you call client.login and nothing between
	client.run     # start the read_loop
	client.login   # logs in and reads all messages until the message is received that indicates that
								 # you may send again. You have to either subscribe before login if you want to handle
								 # them. Alternatively you can use login_noblock
	client.run     # starts the read_loop, without a block it will return immediatly
	client.join("#butler-test") # join one or multiple channels
	client.send_privmsg "Hello world!", "#butler-test" # send a message to one or many receivers
	sleep          # sleep until ctrl-c is pressed
rescue Interrupt
	client.quit("demo terminated")
end
puts
puts "Terminated."
