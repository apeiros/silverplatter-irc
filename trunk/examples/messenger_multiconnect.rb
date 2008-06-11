require 'rubygems'
require 'silverplatter/irc'

include SilverPlatter

client = IRC::Client.new do
	# global config
	port          6667

	nickname      "silverp"
	username      "silver"
	realname      "SilverPlatter-IRC"
	
	ping_interval 600
	reconnect_tries nil
	reconnect_delay 60
	
	server "irc.freenode.org"
	
	connection "freenode_1" do
		# the name is used as default for 'server'
		port 8001 # override the global default
	end
	
	connection "freenode_2"
end

client["freenode_1"].login # selectively perform actions
client.login # perform the action on all connections
client.run do |message|
	# message.connection can be used to distinguish
end
