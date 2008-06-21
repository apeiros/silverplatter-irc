class <<Kernel
	alias projectclass_method_added method_added
	def method_added(name) # :nodoc:
		ProjectClass.send(:undef_method, name) rescue nil
		projectclass_method_added(name)
	end
end

class <<Object
	alias projectclass_method_added method_added
	def method_added(name) # :nodoc:
		ProjectClass.send(:undef_method, name) if ::Object.equal?(self)  rescue nil # all classes inherit from Object
		projectclass_method_added(name)
	end
end

# This class is not written for long running scripts as it leaks symbols.
# It is openstructlike, but a bit more lightweight and blankslate so any method will work
class ProjectClass
	names = private_instance_methods +
	        protected_instance_methods -
	        %w[initialize undef_method inspect]
	names.each { |m| undef_method m }

	attr_reader :__hash__
	
	def initialize(values=nil)
		@__hash__ = values || {}
	end
	
	def []
		@__hash__[key.to_sym] = value
	end
	
	def []=(key,value)
		@__hash__[key.to_sym] = value
	end
	
	def method_missing(name, *args)
		case args.length
			when 0
				if key = name.to_s[/^(.*)\?$/, 1] then
					!!@__hash__[key.to_sym]
				else
					@__hash__[name]
				end
			when 1
				if key = name.to_s[/^(.*)=$/, 1] then
					@__hash__[key.to_sym] = args.first
				else
					super
				end
			else
				super
		end
	end
end
