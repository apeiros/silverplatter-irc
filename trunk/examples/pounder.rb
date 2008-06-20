#!/usr/bin/env ruby

# About
# ==========
# 
# punder.rb is part of a 'bench' suite for silverplatter-irc.
# It throws several thousand PRIVMSG commands at a potential client,
# and in the end throws a ping at it
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
# pundit.

require 'socket'

POUND   = 1000
AGAIN   = 10

data    = DATA.readlines.map { |line| line.chomp+"\r\n" }
prelude = data.shift
ping    = data.pop
pound   = data.join*POUND
server  = TCPServer.open("127.0.0.1", 7777)
client  = server.accept
expect  = %w[USER NICK]
times   = []
round   = 0

puts "Client accepted"
until expect.empty?
	line = client.gets("\r\n")
	expect.delete(expect.find { |e| line =~ /^#{e}/i })
end
client.write prelude
puts "Client logged in", ""

AGAIN.times {
	puts "pounding #{POUND}x #{data.size} messages, round #{round+=1}..."
	start  = Time.now
	client.write(pound)
	client.write(ping)
	line   = client.gets("\r\n")
	stop   = Time.now
	times << stop-start
	raise "Client replied with an invalid response: #{line.inspect}" unless line =~ /^PONG /i
}

min    = times.min
max    = times.max
total  = times.inject(0) { |a,b| a+b }
avg    = total.quo(times.size)
stddev = times.inject(0) { |a,b| a+((b-avg)**2) }.quo(times.size) ** 0.5
puts "Done.", "", "Results:"
printf "Per Message: %.2fms (%d messages/s)\n" \
       "StdDev:      %.2fms (%.2f%%)\n" \
       "Total:       %.2fs\n" \
       "Minimum:     %.2fs (%.2fs)\n" \
       "Average:     %.2fs\n" \
       "Maximum:     %.2fs (%+.2fs)\n" \
       "\n" \
       "Runs:\n",
       (1000*total).quo(POUND*AGAIN*data.size), (POUND*AGAIN*data.size).quo(total),
       (1000*stddev).quo(POUND*data.size), 100.0/avg*stddev,
       total,
       min, min-avg,
       avg,
       max, max-avg
puts times.map { |t| "  %.2fs" % t }

__END__
:testserver.sampleirc.com 001 pundit :Welcome to the freenode IRC Network pundit
:testuser!n=testuser@example.com PRIVMSG #testchannel :this is just a test to test how fast your parser is
PING :payload
