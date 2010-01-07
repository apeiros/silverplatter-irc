#!/usr/bin/env ruby

# Enable running the examples without installation
libdir = File.expand_path(File.dirname(__FILE__)+'/../lib')
$LOAD_PATH.unshift libdir if File.exist?(libdir)

# Require the necessary libraries
begin; require 'rubygems'; rescue LoadError; end
require 'silverplatter/irc/connection'

Usage = "Usage: irccat --server irc.example.com [options] [server] #channel ... [file ...]"

# Provide usage if necessary
if ARGV.empty? || !ARGV.grep(/^(?:(?:--)?help|-h|(?:--)?usage)$/).empty? then
	abort(<<-EOH)
irccat help:
    #{Usage}
--server:     server to connect to
--port:       port to use
--serverpass: password to enter the server
--nick:       nickname to use (default: irccat)
--user:       username to use (default: irccat)
--real:       realname to use (default: silverplatter-irc-cat)
	EOH
end

# extract opts
def extract(opt)
	return unless index = ARGV.index(opt)
	ARGV.delete_at(index)
	ARGV.delete_at(index)
end

BotConfig = {
	:server          => extract('--server') || ARGV.shift,
	:port            => extract('--port') || 6667,
	:serverpass      => extract('--serverpass'),
	
	:nickname        => extract('--nick') || ENV['IRCATNICK'] || 'irccat',
	:username        => extract('--user') || 'irccat',
	:realname        => extract('--real') || 'silverplatter-irc-cat',

	:on_nick_error   => SilverPlatter::IRC::Connection::IncrementOnNickError,
}

# Receivers can be channels and nicknames
receivers = []
receivers << ARGV.shift until (ARGV.first.nil? || File.exist?(ARGV.first))

abort(Usage) unless BotConfig[:server]

Bot = SilverPlatter::IRC::Connection.new(nil, BotConfig)
Bot.connect

Bot.run
Bot.prepare do
	Bot.login
end.wait_for([:RPL_ENDOFMOTD, :ERR_NOMOTD]) # ensure valid_channelname? is used after isupport is known

channels, users = *receivers.partition { |r| Bot.valid_channelname?(r) }
channels.each { |channel| Bot.send_join(channel) }
puts "Pasting to channels #{channels.empty? ? '<none>' : channels.join(', ')} and users #{users.empty? ? '<none>' : users.join(', ')}"

while line = gets # ARGF.gets, will read passed files too
	msg = line.chomp
	Bot.send_privmsg(msg, *channels)
	Bot.send_privmsg(msg, *users) unless users.empty?
end
Bot.quit "My work here is done."
puts "Terminating"
