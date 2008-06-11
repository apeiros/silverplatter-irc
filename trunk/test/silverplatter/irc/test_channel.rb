base = File.expand_path(File.dirname(__FILE__)+'/../../..')
$LOAD_PATH.unshift(base+'/lib') unless $LOAD_PATH.include?(base+'/lib')
$LOAD_PATH.unshift(base+'/test') unless $LOAD_PATH.include?(base+'/test')

require 'silverplatter/irc/channel'
require 'silverplatter/irc/hostmask'
require 'silverplatter/irc/user'
require 'test/unit'
require 'help_assertions'

class TestIRCChannel < Test::Unit::TestCase
	include SilverPlatter::IRC
	
	def setup
		@server = "irc.freenode.org:6667"
	end

	def test_initialize
		assert_raise(ArgumentError) { channel = Channel.new }
		assert_raise(ArgumentError) { channel = Channel.new(@server) }
		assert(channel = Channel.new(@server, "#test"))
	end
	
	def test_casemapping
		assert(channel = Channel.new(@server, "#TEST[\\]^"))
		assert_equal("#test{|}~", channel.compare)
		assert_equal("#test{|}~", channel.to_str)
		assert_equal("#TEST[\\]^", channel.to_s)
		parser = Object.new
		def parser.casemap(str); "foo"; end
		assert(channel.parser = parser)
		assert_equal("foo", channel.compare)
		assert_equal("#TEST[\\]^", channel.to_s)
	end
	
	def test_topic
		created = Time.now
		assert(channel = Channel.new(@server, "#test", "topic", "bynick", created))
		assert_equal("topic", channel.topic.text)
		assert_equal("bynick", channel.topic.set_by)
		assert_equal(created, channel.topic.set_at)
	end
	
	def test_users
		assert(channel = Channel.new(@server, "#test"))
		assert(user1 = User.new(@server, "user1", "testuser", "testhost", "testreal"))
		assert(user2 = User.new(@server, "user2", "testuser", "testhost", "testreal"))
		assert(user3 = User.new(@server, "user3", "testuser2", "testhost", "testreal"))
		assert(user4 = User.new(@server, "user4", "testuser", "testhost2", "testreal"))
		assert_raise(TypeError) { channel.add_user("foo") }
		assert(!channel.include?(user1))
		assert(!channel.include?(user2))
		assert(!channel.include?(user3))
		assert(!channel.include?(user4))
		assert_nothing_raised { channel.add_user(user1) }
		assert(channel.include?(user1))
		assert(!channel.include?(user2))
		assert(!channel.include?(user3))
		assert(!channel.include?(user4))
		assert_nothing_raised { channel.add_user(user2) }
		assert_nothing_raised { channel.add_user(user3) }
		assert_nothing_raised { channel.add_user(user4) }
		assert(channel.include?(user1))
		assert(channel.include?(user2))
		assert(channel.include?(user3))
		assert(channel.include?(user4))
		
		assert_equal(["*!*@testhost"], channel.weak_clones.keys)
		assert_unordered_equal([user1, user2, user3], channel.weak_clones["*!*@testhost"])
		assert_equal(["*!testuser@testhost"], channel.strong_clones.keys)
		assert_unordered_equal([user1, user2], channel.strong_clones["*!testuser@testhost"])

		yielded = []
		channel.each { |u| yielded << u }
		assert_unordered_equal([user1,user2,user3,user4], yielded)
		assert_unordered_equal([user1,user2,user3,user4], channel.users)

		assert_nothing_raised { channel.delete_user(user1) }
		assert_nothing_raised { channel.delete_user(user2) }

		yielded = []
		channel.each { |u| yielded << u }
		assert_unordered_equal([user3,user4], yielded)
		assert_unordered_equal([user3,user4], channel.users)
		assert(!channel.include?(user1))
		assert(!channel.include?(user2))
		assert(channel.include?(user3))
		assert(channel.include?(user4))

		assert_nothing_raised { channel.delete_user(user3) }
		assert_nothing_raised { channel.delete_user(user4) }

		yielded = []
		channel.each { |u| yielded << u }
		assert_equal([], yielded)
		assert_equal([], channel.users)
		assert(!channel.include?(user1))
		assert(!channel.include?(user2))
		assert(!channel.include?(user3))
		assert(!channel.include?(user4))
	end

	def test_inspect
		assert(Channel.new(@server, "#test").inspect)
	end

	def test_comparator
		assert(channel1 = Channel.new(@server, "#test1"))
		assert(channel2 = User.new(@server, "#test2"))
		assert(channel3 = User.new(@server, "#TEST1"))
		assert(channel1 != channel2)
		assert(channel2 != channel3)
		assert(channel1 == channel3)

		assert(channel1 = Channel.new(@server, "#aa"))
		assert(channel2 = Channel.new(@server, "#Ab"))
		assert(channel3 = Channel.new(@server, "#b"))
		assert(channel4 = Channel.new(@server, "#c"))
		assert_equal([channel1, channel2, channel3, channel4], [channel4, channel2, channel1, channel3].sort)
	end
end
