module Log
	class Splitter
		def initialize(*receivers)
			@receivers = receivers
		end
		
		def __delete__(receiver)
			@receivers.delete(receiver)
		end
		
		def __add__(receiver)
			@receivers << receiver
		end
		
		def each(&block)
			@receivers.each(&block)
		end
		
		def method_missing(*a, &b)
			@receivers.each { |r| r.__send__(*a, &b)
		end
		
		def inspect
			"#<%s:%08x %s %s>" %  [
				self.class,
				object_id,
				@receivers.map { |r| r.inspect }.join(', ')
			]
		end
end