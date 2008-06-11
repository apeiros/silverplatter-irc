require File.dirname(__FILE__)+'/../../../bacon_helper'
require 'silverplatter/irc/channel'

include SilverPlatter::IRC

describe 'A new channel' do
	before do
		@channel  = Channel.new("#test")
		@user1 = flexmock("user 1", :compare => "test", :nick => "test")
	end

	it 'should be empty' do
		@channel.should.be.empty
	end
	
	it 'should have a size of 0' do
		@channel.size.should.equal 0
	end
	
	it 'should have no mode' do
		@channel.mode.should.be.empty
	end

	it 'should have no connection' do
		@channel.connection.should.be.nil
	end

	it 'should accept a user' do
		proc { @channel[@user1] = true }.should.not.raise
	end
end

describe 'A populated channel' do
	before do
		@channel  = UserList.new
		@user1 = flexmock("user 1", :compare => "#test1", :nick => "#test1")
		@user2 = flexmock("user 2", :compare => "#test2", :nick => "#test2")
		@user3 = flexmock("user 3", :compare => "#test3", :nick => "#test3")
		@channel[@user1] = true
		@channel[@user2] = true
	end

	it 'should not be empty' do
		@channel.should.not.be.empty
	end
	
	it 'should report the correct size' do
		@channel.size.should.equal 2
	end
	
	it 'should include the user' do
		@channel.should.include @user1
	end

	it 'should recognize the nickname' do
		@channel.should.include_nick @user1.nick
	end

	it 'should recognize the nickname with different casing' do
		@channel.should.include_nick @user1.nick.upcase
	end
	
	it 'should return the users value' do
		@channel.should[@user1]
	end

	it 'should return the user by nick' do
		@channel.by_nick(@user1.nick).should.equal @user1
	end

	it 'should return the user by nick with different casing' do
		@channel.by_nick(@user1.nick.upcase).should.equal @user1
	end

	it 'should return the users value by nick' do
		@channel.value_by_nick(@user1.nick).should.be.true
	end

	it 'should return the users value by nick with different casing' do
		@channel.value_by_nick(@user1.nick.upcase).should.be.true
	end

	it 'should not include a user it does not have' do
		@channel.should.not.include?(@user3)
	end
	
	it 'should return all users' do
		@channel.users.should equal_unordered([@user1, @user2])
	end

	it 'should return all nicks' do
		@channel.nicks.should equal_unordered([@user1.nick, @user2.nick])
	end

	it 'should return all values' do
		@channel.values.should equal_unordered([true, true])
	end

	it 'should iterate over all user->value pairs' do
		@channel.should iterate_unordered([[@user1,true], [@user2,true]])
	end

	it 'should iterate over all users' do
		@channel.should iterate_unordered([@user1, @user2], :each_user)
	end

	it 'should iterate over all nicks' do
		@channel.should iterate_unordered([@user1.nick, @user2.nick], :each_nick)
	end

	it 'should iterate over all values' do
		@channel.should iterate_unordered([true, true], :each_value)
	end

	it 'should delete a user' do
		@channel.include?(@user1).should.be.true
		@channel.delete(@user1)
		@channel.include?(@user1).should.be.false
	end

	it 'should only delete that user' do
		@channel.include?(@user2).should.be.true
		@channel.delete(@user1)
		@channel.include?(@user2).should.be.true
	end

	it 'should delete a user by nick' do
		@channel.include?(@user1).should.be.true
		@channel.delete_nick(@user1.nick)
		@channel.should.not.include @user1
	end

	it 'should only delete that user by nick' do
		@channel.include?(@user2).should.be.true
		@channel.delete_nick(@user1.nick)
		@channel.include?(@user2).should.be.true
	end

	it 'should delete a user by nick with different casing' do
		@channel.include?(@user1).should.be.true
		@channel.delete_nick(@user1.nick.upcase)
		@channel.include?(@user1).should.be.false
	end

	it 'should only delete that user by nick with different casing' do
		@channel.include?(@user2).should.be.true
		@channel.delete_nick(@user1.nick.upcase)
		@channel.include?(@user2).should.be.true
	end

	it 'should invoke delete_user on all users' do
		flexmock(@user1).should_receive(:delete_channel).once
		flexmock(@user2).should_receive(:delete_channel).once
		@channel.delete_channel("#foo")
	end

	it 'should be empty after clear' do
		@channel.clear
		@channel.should.be.empty
	end
end

describe "A channels comparability" do
	before do
		@channel1 = Channel.new("#test1")
		@channel2 = Channel.new("#test2")
		@channel3 = Channel.new("#TEST3")
		@channel4 = Channel.new("#test4")
	end

	it 'a channel should be equal to itself' do
		@channel1.should.be == @channel1
	end

	it 'a channel should not be equal to another channel' do
		@channel1.should.not.be == @channel2
	end

	it 'should raise if compared to something that is not a channel' do
		proc { @channel1 == "#test1" }.should.raise(ArgumentError)
	end

	it 'a channel should be sorted correctly' do
		[@channel4, @channel2, @channel3, @channel1].sort.should.equal [@channel1, @channel2, @channel3, @channel4]
	end
end

describe "A stores channelmodes" do
	before do
		@channel1 = Channel.new("#test1")
	end

	it 'should accept a new mode' do
		proc { @channel1.mode.add("t") }.should.not.raise
		@channel1.mode.should["t"]
		@channel1.mode.to_hash.should.equal({"t" => true})
	end
end
