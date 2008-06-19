#!/usr/bin/env ruby

# Enable running the examples without installation
libdir = File.expand_path(File.dirname(__FILE__)+'/../lib')
$LOAD_PATH.unshift libdir if File.exist?(libdir)

# Require the necessary libraries
begin; require 'rubygems'; rescue LoadError; end
require 'silverplatter/irc/connection'

# extract opts
def extract(opt)
	return unless index = ARGV.index(opt)
	ARGV.delete_at(index)
	ARGV.delete_at(index)
end

BotConfig = {
	:server          => extract '--server',
	:port            => extract '--port' || 6667,
	:serverpass      => extract '--serverpass',
	
	:join            => [],

	:nickname        => extract '--nick' || 'irccat',
	:username        => extract '--user' || 'irccat',
	:realname        => extract '--real' || 'silverplatter-irc-cat',
	
	:on_nick_error   => SilverPlatter::IRC::Connection::IncrementOnNickError,
}
BotConfig[:join] = ARGV.shift until File.exist?(ARGV.first)

if ARGV.include?('--help') || ARGV.include?('-h') then
	abort(<<-EOH)
irccat help:
    Usage: irccat --server irc.example.com [options] #channel ... [file ...]
--server:     server to connect to
--port:       port to use
--serverpass: password to enter the server
--nick:       nickname to use (default: irccat)
--user:       username to use (default: irccat)
--real:       realname to use (default: silverplatter-irc-cat)
	EOH
elsif !BotConfig[:server] || ARGV.empty? then
	abort("Usage: echo 'text' | irccat --server irc.freenode.org #channel ...")
end

Bot = SilverPlatter::IRC::Connection.new(nil, BotConfig)
Bot.connect
Bot.run
Bot.login
while line = gets
	Bot.privmsg(line.chomp, *BotConfig[:join])
end
Bot.quit "My work here is done."
