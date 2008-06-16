# Enable running the examples without installation
libdir = File.expand_path(File.dirname(__FILE__)+'/../lib')
$LOAD_PATH.unshift libdir if File.exist?(libdir)

require 'rubygems'
require 'silverplatter/irc/socket'

include SilverPlatter

irc = IRC::Socket.new("irc.freenode.org", :port => 6667)
irc.connect
irc.login('sp_irc_socket', 'SilverPlatter', 'SilverPlatter-IRC')
until irc.read =~ /\A\S*\s+376\s+/; end
irc.send_join("#butler-test")
sleep 1
irc.send_privmsg("Hi all of you in #butler-test!", "#butler-test")
sleep 1
irc.send_part("Part of the example code", "#butler-test")
sleep 1
irc.send_join("#butler-test")
sleep 1
irc.quit("Example done")
puts "Finished"
