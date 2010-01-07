#!/usr/bin/env ruby

# About
# ==========
# 
# poundit.rb is part of a 'bench' suite for silverplatter-irc.
# It should receive a ton of messages from pounder.rb and process
# them as fast as possible.
#
# How to use
# ==========
# 
#   cd examples
#   ./pounder.rb
#   ./poundit.rb
#
# Enjoy!
# If you want to test your own parser against it, connect using 127.0.0.1:7777 and use the nick
# fooby.

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
client = IRC::Connection.new "127.0.0.1", :port => 7777, :nickname => 'pundit'
$VERBOSE = true
Thread.abort_on_exception = true
sleep 1

begin
	client.connect
	client.run
	client.login
	sleep
rescue Interrupt => e
	puts e.class
	client.quit("demo terminated")
end
puts
puts "Terminated."
