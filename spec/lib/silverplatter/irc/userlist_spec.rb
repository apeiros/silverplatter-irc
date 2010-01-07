require File.dirname(__FILE__)+'/../../../bacon_helper'
require 'silverplatter/irc/userlist'

include SilverPlatter::IRC

describe 'A new userlist' do
	before do
		@list  = UserList.new
		@user1 = flexmock("user 1", :compare => "test", :nick => "test")
	end

	it 'should be empty' do
		@list.should.be.empty
	end
	
	it 'should have a size of 0' do
		@list.size.should.equal 0
	end
	
	it 'should have no connection' do
		@list.connection.should.be.nil
	end
	
	it 'should accept a user' do
		proc { @list[@user1] = true }.should.not.raise
	end
end

describe 'A populated userlist' do
	before do
		@list  = UserList.new
		@user1 = flexmock(User.new, :compare => "#test1", :nick => "#test1")
		@user2 = flexmock(User.new, :compare => "#test2", :nick => "#test2")
		@user3 = flexmock(User.new, :compare => "#test3", :nick => "#test3")
		@list[@user1] = true
		@list[@user2] = true
	end

	it 'should not be empty' do
		@list.should.not.be.empty?
	end
	
	it 'should report the correct size' do
		@list.size.should.equal 2
	end
	
	it 'should include the user' do
		@list.should.include @user1
	end

	it 'should recognize the nickname' do
		@list.should.include_nick @user1.nick
	end

	it 'should recognize the nickname with different casing' do
		@list.should.include_nick @user1.nick.upcase
	end
	
	it 'should return the users value' do
		@list.should[@user1]
	end

	it 'should return the user by nick' do
		@list.by_nick(@user1.nick).should.equal @user1
	end

	it 'should return the user by nick with different casing' do
		@list.by_nick(@user1.nick.upcase).should.equal @user1
	end

	it 'should return the users value by nick' do
		@list.value_by_nick(@user1.nick).should.be.true
	end

	it 'should return the users value by nick with different casing' do
		@list.value_by_nick(@user1.nick.upcase).should.be.true
	end

	it 'should not include a user it does not have' do
		@list.should.not.include?(@user3)
	end
	
	it 'should return all users' do
		@list.users.should equal_unordered([@user1, @user2])
	end

	it 'should return all nicks' do
		@list.nicks.should equal_unordered([@user1.nick, @user2.nick])
	end

	it 'should return all values' do
		@list.values.should equal_unordered([true, true])
	end

	it 'should iterate over all user->value pairs' do
		@list.should iterate_unordered([[@user1,true], [@user2,true]])
	end

	it 'should iterate over all users' do
		@list.should iterate_unordered([@user1, @user2], :each_user)
	end

	it 'should iterate over all nicks' do
		@list.should iterate_unordered([@user1.nick, @user2.nick], :each_nick)
	end

	it 'should iterate over all values' do
		@list.should iterate_unordered([true, true], :each_value)
	end

	it 'should delete a user' do
		@list.include?(@user1).should.be.true
		@list.delete(@user1)
		@list.include?(@user1).should.be.false
	end

	it 'should only delete that user' do
		@list.include?(@user2).should.be.true
		@list.delete(@user1)
		@list.include?(@user2).should.be.true
	end

	it 'should delete a user by nick' do
		@list.include?(@user1).should.be.true
		@list.delete_nick(@user1.nick)
		@list.include?(@user1).should.be.false
	end

	it 'should only delete that user by nick' do
		@list.include?(@user2).should.be.true
		@list.delete_nick(@user1.nick)
		@list.include?(@user2).should.be.true
	end

	it 'should delete a user by nick with different casing' do
		@list.include?(@user1).should.be.true
		@list.delete_nick(@user1.nick.upcase)
		@list.include?(@user1).should.be.false
	end

	it 'should only delete that user by nick with different casing' do
		@list.include?(@user2).should.be.true
		@list.delete_nick(@user1.nick.upcase)
		@list.include?(@user2).should.be.true
	end

	it 'should invoke delete_user on all users' do
		flexmock(@user1).should_receive(:delete_channel).once
		flexmock(@user2).should_receive(:delete_channel).once
		@list.delete_channel("#foo")
	end

	it 'should be empty after clear' do
		@list.clear
		@list.should.be.empty
	end
end
