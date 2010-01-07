base = File.expand_path(File.dirname(__FILE__)+'/../../..')
$LOAD_PATH.unshift(base+'/lib') unless $LOAD_PATH.include?(base+'/lib')
$LOAD_PATH.unshift(base+'/test') unless $LOAD_PATH.include?(base+'/test')

require 'silverplatter/irc/channel'
require 'silverplatter/irc/channellist'
require 'silverplatter/irc/user'
require 'test/unit'
require 'help_assertions'

class TestIRCChannel < Test::Unit::TestCase
	include SilverPlatter::IRC
	
	def setup
		@server = "irc.freenode.org:6667"
		@list   = ChannelList.new(@server)
		@list.create("#butler")
		@list.create("#silverplatter")
		@list.create("#SILLY[\\]^")
	end

	def test_initialize
		assert(ChannelList.new(@server))
	end
	
	def test_direct_lookup
		assert(@list["#butler"])
		assert_nil(@list["#inexistent"])
	end
	
	def test_casemapped_lookup
		assert(@list["#BuTlEr"])
		assert_nil(@list["#silly{|}~"])
	end
	
	def test_parser_casemapped_lookup
		flunk("evil parser casemapping")
		parser = Object.new
		def parser.casemap(str); "foo"; end
		@list.parser = parser
		assert(@list["#foo"])
		assert_nil(@list["#silly{|}~"])
	end
	
	def test_topic
		created = Time.now
		assert(@list.create("#topic", "topic", "by", created))
		assert_equal("topic", @list["#topic"].topic.text)
		assert_equal("topic", @list["#topic"].topic.set_by)
		assert_equal("topic", @list["#topic"].topic.set_at)
	end
	
	def test_users
	end

	def test_inspect
	end

	def test_comparator
	end
end
