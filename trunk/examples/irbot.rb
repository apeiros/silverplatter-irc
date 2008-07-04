# HOW TO USE
# 
# A)
#   irb -r irbbot
# B)
# Start IRB and then run:
#   load 'irbbot.rb'
#
# The bot is available to you in the constant Bot
# It features a few little conveniences for you, e.g. the following works:
# 
#
# Configure as you wish

$VERBOSE                  = true
Thread.abort_on_exception = true

BotConfig = {
	:server          => "irc.freenode.org",
	:port            => 6667,
	:serverpass      => nil,

	:nickname        => ENV["IRBOTNICK"] || "silverp",
	:username        => "silver",
	:realname        => "SilverPlatter-IRC",
	
	:join            => %w[silverplatter],
	
	:ping_interval   => 600,
	:reconnect_tries => nil,
	:reconnect_delay => 60,

	:on_nick_error   => proc { |connection, original_nick, current_nick, tries|
		$stdout.print "#{current_nick} is already in use, please chose another: "
		$stdout.flush
		$stdin.gets.chomp
	},
}



# Enable running the examples without installation
libdir = File.expand_path(File.dirname(__FILE__)+'/../lib')
$LOAD_PATH.unshift libdir if File.exist?(libdir)

# Require the necessary libraries
begin; require 'rubygems'; rescue LoadError; end
require 'silverplatter/irc/connection'
require 'pp' # everybody and his/her mom need pp

include SilverPlatter
Bot = IRC::Connection.new(nil, BotConfig)

class IRC::UserList; alias / []; end
class IRC::ChannelList; alias / []; end
class <<Bot
	def /(value)
		valid_channelname?(value) ? channel_by_name(value) : user_by_nick(value)
	end
end

Bot.connect
Bot.run
Bot.login
