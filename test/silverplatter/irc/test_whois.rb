base = File.expand_path(File.dirname(__FILE__)+'/../../..')
$LOAD_PATH.unshift(base+'/lib') unless $LOAD_PATH.include?(base+'/lib')
$LOAD_PATH.unshift(base+'/test') unless $LOAD_PATH.include?(base+'/test')

require 'silverplatter/irc/whois'
require 'test/unit'
require 'help_assertions'

class TestIRCWhois < Test::Unit::TestCase
	include SilverPlatter::IRC
	
	def test_initialize
		assert(whois = Whois.new())
		assert_nil(whois.server)
		assert_nil(whois.exists)
		assert_nil(whois.nick)
		assert_nil(whois.user)
		assert_nil(whois.host)
		assert_nil(whois.real)
		assert_nil(whois.registered)
		assert_nil(whois.channels)
		assert_nil(whois.server)
		assert_nil(whois.idle)
		assert_nil(whois.signon)
	end
end
