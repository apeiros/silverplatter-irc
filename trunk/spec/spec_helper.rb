

require 'rubygems'
require 'spec'

$:.unshift File.join(File.dirname(__FILE__), '../lib')

Spec::Runner.configure do |config|
  # NOTE: My preference
  config.mock_with :flexmock
end
