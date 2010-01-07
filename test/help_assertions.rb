module Test::Unit::Assertions
	def assert_unordered_equal(expected, actual, message=nil)
		full_message = build_message(message, "<?> expected but was\n<?>.\n", expected, actual)
		assert_block(full_message) {
			seen = Hash.new(0)
			expected.each { |e| seen[e] += 1 }
			actual.each { |e| seen[e] -= 1 }
			seen.invert.keys == [0]
		}
	end
	
	# assert_yields([1,2,3].method(:each), [], [1,2,3])
	def assert_yields(method, args, should_yield, message=nil)
	end
	
	def assert_yields_unordered
	end
end