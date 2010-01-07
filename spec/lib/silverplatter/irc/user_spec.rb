require File.dirname(__FILE__)+'/../../../bacon_helper'
require 'silverplatter/irc/userlist'

include SilverPlatter::IRC

describe 'when just constructed' do
	before do
		@user = User.new("testnick", "testuser", "testhost", "testreal")
	end

	it "should construct empty" do
		user = User.new
		
		user.nick.should.be.nil?
		user.user.should.be.nil?
		user.real.should.be.nil?
		user.host.should.be.nil?
	end

	it "should assign fields on construction" do
		@user.nick.should == 'testnick'
		@user.user.should == 'testuser'
		@user.host.should == 'testhost'
		@user.real.should == 'testreal'
	end

	it "should initially be invisible" do
		@user.should.be.invisible
	end

	it "should allow changing status to :online" do
		@user.change_visibility(true).should.be.true
		@user.should.be.visible
	end

	it "should have away equal to nil" do
		@user.away.should.be.nil
	end

	it "should not be away?" do
		@user.should.not.be.away
	end

	it "should not be me" do
		# Note: maybe install an accessor for the test?
		@user.should.not.be.me
	end

	it "should behave correctly with myself set to true" do
		@user.instance_variable_set(:@me, true)
		@user.should.be.me
	end
	
	it "should answer to inspect" do
		@user.inspect.should.not.be.nil
		@user.inspect.class.should.be == String
	end

	it "should have correct hostmask" do
		@user.hostmask.to_s.should == "testnick!testuser@testhost"
	end 
end

describe 'when visible' do
	before do
		@user = User.new("testnick", "testuser", "testhost", "testreal")
		@user.change_visibility(true)
	end
	
	it "should be visible" do
		@user.should.be.visible
	end

	it "should allow changing to :out_of_sight" do
		@user.change_visibility(false).should.be.true
		@user.should.not.be.visible
	end
end

describe 'when away with "foobar"' do
	before do
		@user = User.new("testnick", "testuser", "testhost", "testreal")
		@user.away = 'foobar'
	end
	
	it "should allow reading back reason" do
		@user.away.should == 'foobar'
	end
	it "should be away?" do
		@user.should.be.away
	end 
end

describe "constructed with arguments (with relation to parser)" do
	before do
		@user = User.new("NICK[\\]^", "x", "x", "x")
	end
	
	it "should set compare when constructing" do
		@user.compare.should == 'nick{|}~'
	end 

	it "should call set_compare when assigning to #nick" do
		flexmock(@user).should_receive(:set_compare).once
		@user.nick = 'some nick'
	end

	it "should be able to use set_compare to set the #compare field" do
		@user.nick = 'OTHER[\\]^'
		@user.compare.should == 'other{|}~'
	end
	
	it "should compare by rfc when there is no parser" do
		nick = flexmock(:nick)
		nick.should_receive(:tr).with(User::RFC1459_Upper, User::RFC1459_Lower).once
	
		@user.instance_variable_set('@nick', nick)
		@user.send :set_compare
	end

	it "should use the given connection's casemap" do
		connection = flexmock(:connection, :casemap => :return_value)
		user       = User.new("NICK[\\]^", "x", "x", "x", connection)
		
		user.nick = 'OTHER[\\]^'
		
		user.compare.should == :return_value
	end

	it "should return Incomparable if there is no nick" do
		user = User.new
		user.compare.should == User::Incomparable
	end
end

describe 'when comparing objects' do
	before do
		@a = User.new("testnick", "testuser", "testhost", "testreal")
		@b = User.new("testnick", "testuser", "testhost", "testreal")
	end
	
	it "should be equal users (==)" do
		@a.should == @b
	end

	it "should not be an equal user anymore after modification of an attribute" do
		@b.nick = 'foo'
		@a.should.not == @b
	end 
end

describe 'when sorting' do
	before do
		@users = []
		@users << User.new("aa", "x", "x", "x")
		@users << User.new("Ab", "b", "b", "b")
		@users << User.new("b", "a", "a", "a")
		@users << User.new
	end
	
	it "should allow sorting into a given order (as in @users)" do
		result = [3,2,1,0].collect { |i| @users[i] }.sort
		
		result.should == @users
	end
end
