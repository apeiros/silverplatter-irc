base = File.expand_path(File.dirname(__FILE__)+'/../../..')
$LOAD_PATH.unshift(base+'/lib') unless $LOAD_PATH.include?(base+'/lib')
$LOAD_PATH.unshift(base+'/test') unless $LOAD_PATH.include?(base+'/test')

require 'silverplatter/irc/topic'
require 'test/unit'

class TestIRCTopic < Test::Unit::TestCase
	include SilverPlatter::IRC

	def test_initialize
		created = Time.now
		assert(topic = Topic.new("data", "nick", created))
		assert_equal("data", topic.text)
		assert_equal("nick", topic.set_by)
		assert_equal(created, topic.set_at)
	end
	
	def test_accessors
		created  = Time.now
		created2 = created+100
		assert(topic = Topic.new("data", "nick", created))
		assert(topic.text = "newdata")
		assert(topic.set_by = "newnick")
		assert(topic.set_at = created2)
		assert_equal("newdata", topic.text)
		assert_equal("newnick", topic.set_by)
		assert_equal(created2, topic.set_at)
	end
	
	def test_inspect
		created = Time.now
		assert(Topic.new("data", "nick", created).inspect)
	end
end
