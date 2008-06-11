require File.dirname(__FILE__)+'/../../../bacon_helper'
require 'silverplatter/irc/channel'

include SilverPlatter::IRC

describe 'A new channellist' do
	before do
		@list  = ChannelList.new
		@chan1 = flexmock("channel 1", :compare => "#test", :name => "#test")
	end
	
	it 'should be empty' do
		@list.should.be.empty?
	end
	
	it 'should have a size of 0' do
		@list.size.should.equal 0
	end
	
	it 'should have no connection' do
		@list.connection.should.be.nil?
	end
	
	it 'should accept a channel' do
		proc { @list[@chan1] = true }.should.not.raise
	end
end

describe 'A populated channellist' do
	before do
		@list  = ChannelList.new
		@chan1 = flexmock("channel 1", :compare => "#test1", :name => "#test1")
		@chan2 = flexmock("channel 2", :compare => "#test2", :name => "#test2")
		@chan3 = flexmock("channel 3", :compare => "#test3", :name => "#test3")
		@list[@chan1] = true
		@list[@chan2] = true
	end

	it 'should not be empty' do
		@list.should.not.be.empty?
	end
	
	it 'should report the correct size' do
		@list.size.should.equal 2
	end
	
	it 'should include the channel' do
		@list.should.include?(@chan1)
	end

	it 'should recognize the channelname' do
		@list.should.include_name?(@chan1.name)
	end

	it 'should recognize the channelname with different casing' do
		@list.should.include_name?(@chan1.name.upcase)
	end
	
	it 'should return the channels value' do
		@list.should[@chan1]
	end

	it 'should return the channel by name' do
		@list.by_name(@chan1.name).should.equal @chan1
	end

	it 'should return the channels value by name with different casing' do
		@list.by_name(@chan1.name.upcase).should.equal @chan1
	end

	it 'should return the channels value by name' do
		@list.value_by_name(@chan1.name).should.be.true?
	end

	it 'should return the channels value by name with different casing' do
		@list.value_by_name(@chan1.name.upcase).should.be.true?
	end

	it 'should not include a channel it does not have' do
		@list.should.not.include?(@chan3)
	end
	
	it 'should return all channels' do
		@list.channels.should equal_unordered([@chan1, @chan2])
	end

	it 'should return all names' do
		@list.names.should equal_unordered([@chan1.name, @chan2.name])
	end

	it 'should return all values' do
		@list.values.should equal_unordered([true, true])
	end

	it 'should iterate over all channel->value pairs' do
		@list.should iterate_unordered([[@chan1,true], [@chan2,true]])
	end

	it 'should iterate over all channels' do
		@list.should iterate_unordered([@chan1, @chan2], :each_channel)
	end

	it 'should iterate over all names' do
		@list.should iterate_unordered([@chan1.name, @chan2.name], :each_name)
	end

	it 'should iterate over all values' do
		@list.should iterate_unordered([true, true], :each_value)
	end

	it 'should delete a channel' do
		@list.include?(@chan1).should.be.true
		@list.delete(@chan1)
		@list.include?(@chan1).should.be.false
	end

	it 'should only delete that channel' do
		@list.include?(@chan2).should.be.true
		@list.delete(@chan1)
		@list.include?(@chan2).should.be.true
	end

	it 'should delete a channel by name' do
		@list.include?(@chan1).should.be.true
		@list.delete_name(@chan1.name)
		@list.include?(@chan1).should.be.false
	end

	it 'should only delete that channel by name' do
		@list.include?(@chan2).should.be.true
		@list.delete_name(@chan1.name)
		@list.include?(@chan2).should.be.true
	end

	it 'should delete a channel by name with different casing' do
		@list.include?(@chan1).should.be.true
		@list.delete_name(@chan1.name.upcase)
		@list.include?(@chan1).should.be.false
	end

	it 'should only delete that channel by name with different casing' do
		@list.include?(@chan2).should.be.true
		@list.delete_name(@chan1.name.upcase)
		@list.include?(@chan2).should.be.true
	end

	it 'should invoke delete_user on all channels' do
		flexmock(@chan1).should_receive(:delete_user).once
		flexmock(@chan2).should_receive(:delete_user).once
		@list.delete_user("foo")
	end

	it 'should be empty after clear' do
		@list.clear
		@list.should.be.empty?
	end
end
