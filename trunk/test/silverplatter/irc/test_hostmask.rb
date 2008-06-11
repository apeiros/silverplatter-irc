base = File.expand_path(File.dirname(__FILE__)+'/../../..')
$LOAD_PATH.unshift(base+'/lib') unless $LOAD_PATH.include?(base+'/lib')
$LOAD_PATH.unshift(base+'/test') unless $LOAD_PATH.include?(base+'/test')

require 'silverplatter/irc/hostmask'
require 'silverplatter/irc/user'
require 'test/unit'
require 'help_assertions'

class TestIRCHostmask < Test::Unit::TestCase
	include SilverPlatter::IRC
	
	def setup
	end

	def test_initialize
		assert(mask=Hostmask.new("FOO", "bar", "baz"))
		assert_equal("foo!bar@baz", mask.hostmask)
		assert_equal(/\A(foo)!(bar)@(baz)\z/, mask.regex)
		assert(Hostmask.from_mask("foo!bar@baz"))
		assert_equal("foo!bar@baz", mask.hostmask)
		assert_equal(/\A(foo)!(bar)@(baz)\z/, mask.regex)
		assert_raise(ArgumentError) { Hostmask.from_mask("foobaz") }
	end
	
	def test_matching
		assert(mask=Hostmask.new("FOO", "bar", "baz"))
		assert(mask =~ "foo!bar@baz")
		assert(mask !~ "foo!quuz@baz")
		assert_equal(%w[foo bar baz], mask.match("foo!bar@baz").captures)
		assert_nil(mask.match("foo!quuz@baz"))

		assert(mask=Hostmask.new("{|i|}", "bar", "baz"))
		assert(mask =~ "[\\I\\]!bar@baz")
		assert(mask !~ "foo!quuz@baz")

		assert(mask=Hostmask.new("foo", "bar", "baz.ch"))
		assert(mask =~ "foo!bar@baz.ch")
		assert(mask !~ "foo!bar@bazXch")

		assert(mask=Hostmask.new("*", "bar", "baz"))
		assert(mask =~ "foo!bar@baz")
		assert(mask !~ "foo!quuz@baz")

		assert(mask=Hostmask.new("foo", "?=bar", "baz"))
		assert(mask =~ "foo!n=bar@baz")
		assert(mask =~ "foo!i=bar@baz")
		assert(mask !~ "foo!i=baz@baz")

		assert(mask=Hostmask.new("*", "bar", "baz"))
		assert(user1=User.new(nil, "foo", "bar", "baz"))
		assert(user2=User.new(nil, "quuz", "bar", "baz"))
		assert(user3=User.new(nil, "foo", "quuz", "baz"))
		assert(mask =~ user1)
		assert(mask =~ user2)
		assert(mask !~ user3)
	end
	
	def test_parser
		parser = Object.new
		def parser.casemap(str); "foo"; end

		assert(mask=Hostmask.new("testnick", "testuser", "testhost"))
		assert_equal("testnick!testuser@testhost", mask.hostmask)
		assert_equal(/\A(testnick)!(testuser)@(testhost)\z/, mask.regex)

		mask.parser=parser
		assert_equal("foo!testuser@testhost", mask.hostmask)
		assert_equal(/\A(foo)!(testuser)@(testhost)\z/, mask.regex)

		assert(mask=Hostmask.new("testnick", "testuser", "testhost", parser))
		assert_equal("foo!testuser@testhost", mask.hostmask)
		assert_equal(/\A(foo)!(testuser)@(testhost)\z/, mask.regex)

		assert(mask=Hostmask.from_mask("testnick!testuser@testhost", parser))
		assert_equal("foo!testuser@testhost", mask.hostmask)
		assert_equal(/\A(foo)!(testuser)@(testhost)\z/, mask.regex)
	end
	
	def test_inspect
		assert(Hostmask.new("foo", "bar", "baz").inspect)
	end
end

__END__
"A\\t\\b\\v"
