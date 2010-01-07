base = File.expand_path(File.dirname(__FILE__)+'/../../..')
$LOAD_PATH.unshift(base+'/lib') unless $LOAD_PATH.include?(base+'/lib')
$LOAD_PATH.unshift(base+'/test') unless $LOAD_PATH.include?(base+'/test')

require 'silverplatter/irc/channel'
require 'silverplatter/irc/hostmask'
require 'silverplatter/irc/user'
require 'test/unit'

class TestIRCUser < Test::Unit::TestCase
	include SilverPlatter::IRC
	
	def setup
		@server = "irc.freenode.org:6667".freeze
	end

	def test_initialize
		assert(user = User.new(@server))
		assert_nil(user.nick)
		assert_nil(user.user)
		assert_nil(user.real)
		assert_nil(user.host)
		assert_equal(:out_of_sight, user.status)

		assert(user = User.new(@server, "testnick", "testuser", "testhost", "testreal"))
		assert_equal("testnick", user.nick)
		assert_equal("testuser", user.user)
		assert_equal("testhost", user.host)
		assert_equal("testreal", user.real)
		assert_equal(:out_of_sight, user.status)
	end
	
	def test_status
		assert(user = User.new(@server))
		assert_equal(:out_of_sight, user.status)
		assert_raise(ArgumentError) { user.change_status(:invalid) }
		assert(user.change_status(:online))
		assert(!user.change_status(:online))
		assert_equal(:online, user.status)
		assert(user.change_status(:out_of_sight))
		assert_equal(:out_of_sight, user.status)
	end
	
	def test_away
		assert(user = User.new(@server))
		assert_nil(user.away)
		assert(!user.away?)
		assert(user.away = "foobar")
		assert_equal("foobar", user.away)
		assert(user.away?)
	end
	
	def test_myself
		assert(user = User.new(@server))
		assert(!user.me?)
		assert(user.myself = true)
		assert(user.me?)
		assert(!user.myself = false)
		assert(!user.me?)
	end
	
	def test_equality
		assert(user1 = User.new(@server, "testnick1", "testuser2", "testhost3", "testreal4"))
		assert(user2 = User.new(@server, "testnick", "testuser", "testhost", "testreal"))
		assert(user3 = User.new(@server, "testnick", "testuser", "testhost", "testreal"))
		assert(user1 != user2)
		assert(user2 == user3)
		assert(user1 != user3)
	end
	
	def test_comparator
		assert(user1 = User.new(@server, "aa", "x", "x", "x"))
		assert(user2 = User.new(@server, "Ab", "b", "b", "b"))
		assert(user3 = User.new(@server, "b", "a", "a", "a"))
		assert(user4 = User.new(@server))
		assert_equal([user1, user2, user3, user4], [user1, user4, user2, user3].sort)
	end

	def test_parser
		assert(user = User.new(@server, "NICK[\\]^", "x", "x", "x"))
		assert_equal("nick{|}~", user.compare)
		assert(user.nick = "OTHER[\\]^")
		assert_equal("other{|}~", user.compare)
		parser = Object.new
		def parser.casemap(str); "foo"; end
		assert(user.parser = parser)
		assert_equal("foo", user.compare)
		assert(user.nick = "newnick")
		assert_equal("foo", user.compare)
	end
	
	def test_inspect
		assert(User.new(@server, "a", "b", "c", "d").inspect)
	end

	def test_hostmask
		assert(user = User.new(@server, "testnick", "testuser", "testhost", "testreal"))
		assert_equal("testnick!testuser@testhost", user.hostmask.to_s)
	end

	def test_compare
		assert(user1 = User.new(@server, "testnick", "testuser", "testhost", "testreal"))
		assert(user2 = User.new(@server, "TESTNICK", "testuser", "testhost", "testreal"))
		assert(user3 = User.new(@server))
		assert_equal("testnick", user1.to_str)
		assert_equal("testnick", user2.to_str)
		assert_equal("testnick", user1.compare)
		assert_equal("\xff", user3.compare)
	end
	
	def test_update
		assert(user = User.new(@server))
		assert_nil(user.nick)
		assert_nil(user.user)
		assert_nil(user.real)
		assert_nil(user.host)

		assert(user.update("testuser", "testhost", "testreal"))
		assert_nil(user.nick)
		assert_equal("testuser", user.user)
		assert_equal("testhost", user.host)
		assert_equal("testreal", user.real)

		assert(user.nick = "testnick")
		assert_equal("testnick", user.nick)
		assert_equal("testuser", user.user)
		assert_equal("testhost", user.host)
		assert_equal("testreal", user.real)

		assert(user = User.new(@server, "testnick", "testuser", "testhost", "testreal"))
		assert_equal("testnick", user.nick)
		assert_equal("testuser", user.user)
		assert_equal("testhost", user.host)
		assert_equal("testreal", user.real)

		assert(user.update("testuser2", "testhost2", "testreal2"))
		assert_equal("testnick", user.nick)
		assert_equal("testuser2", user.user)
		assert_equal("testhost2", user.host)
		assert_equal("testreal2", user.real)

		assert(user.nick = "testnick2")
		assert_equal("testnick2", user.nick)
		assert_equal("testuser2", user.user)
		assert_equal("testhost2", user.host)
		assert_equal("testreal2", user.real)
	end

	def test_channels
		assert(user = User.new(@server))
		assert(channel = Channel.new(@server, "#test"))
		assert(other   = Channel.new(@server, "#test2"))
		assert(user.add_channel(channel))
		assert(user.in?(channel))
		assert(!user.in?(other))
		assert_raise(TypeError) { user.in?("#test") }
		assert_raise(TypeError) { user.add_channel("#test") }
		assert_raise(TypeError) { user.delete_channel("#test") }
		assert_equal([channel], user.channels)
		yielded = []
		user.each { |c| yielded << c }
		assert_equal([channel], yielded)

		assert_nothing_raised { user.delete_channel(other) }
		assert_nothing_raised { user.delete_channel(channel) }
		assert(!user.in?(channel))
		assert(!user.in?(other))
		yielded = []
		user.each { |c| yielded << c }
		assert_equal([], yielded)
	end
	
	def test_common_channels
		assert(user1 = User.new(@server))
		assert(user2 = User.new(@server))
		assert(channel1 = Channel.new(@server, "#a"))
		assert(channel2 = Channel.new(@server, "#b"))
		assert(channel3 = Channel.new(@server, "#c"))
		assert(channel4 = Channel.new(@server, "#d"))
		assert(channel5 = Channel.new(@server, "#e"))
		assert(!user1.common_channels?(user2))
		assert(!user2.common_channels?(user1))
		assert_equal([], user1.common_channels(user2))
		assert_equal([], user2.common_channels(user1))
		assert_nothing_raised { user1.add_channel(channel1) }
		assert_nothing_raised { user1.add_channel(channel2) }
		assert_nothing_raised { user1.add_channel(channel3) }
		assert_nothing_raised { user2.add_channel(channel1) }
		assert_nothing_raised { user2.add_channel(channel4) }
		assert_nothing_raised { user2.add_channel(channel5) }
		assert(user1.common_channels?(user2))
		assert(user2.common_channels?(user1))
		assert_equal([channel1], user1.common_channels(user2))
		assert_equal([channel1], user2.common_channels(user1))
	end
	
	def test_flags
		assert(user    = User.new(@server))
		assert(channel = Channel.new(@server, "#test"))
		assert_raise(TypeError) { user.op?("#test") }
		assert_raise(TypeError) { user.voice?("#test") }
		assert_raise(TypeError) { user.uop?("#test") }
		assert(!user.op?(channel))
		assert(!user.voice?(channel))
		assert(!user.uop?(channel))

		assert_raise(ArgumentError) { user.add_flag(channel, "@") } # Channel not added to user
		assert_nothing_raised { user.add_channel(channel) }
		assert_raise(ArgumentError) { user.add_flag("#test", "@") } # must be Channel
		assert_raise(ArgumentError) { user.add_flag(channel, "x") } # must be a valid Flag
		assert_nothing_raised { user.add_flag(channel, "@") }

		assert(user.op?(channel))
		assert(!user.voice?(channel))
		assert(!user.uop?(channel))

		assert_nothing_raised { user.add_flag(channel, "+") }

		assert(user.op?(channel))
		assert(user.voice?(channel))
		assert(!user.uop?(channel))

		assert_nothing_raised { user.add_flag(channel, "-") }

		assert(user.op?(channel))
		assert(user.voice?(channel))
		assert(user.uop?(channel))

		assert_nothing_raised { user.delete_flag(channel, "+") }

		assert(user.op?(channel))
		assert(!user.voice?(channel))
		assert(user.uop?(channel))

		assert_nothing_raised { user.delete_flag(channel, "-") }

		assert(user.op?(channel))
		assert(!user.voice?(channel))
		assert(!user.uop?(channel))

		assert_nothing_raised { user.delete_flag(channel, "@") }

		assert(!user.op?(channel))
		assert(!user.voice?(channel))
		assert(!user.uop?(channel))
	end
end
