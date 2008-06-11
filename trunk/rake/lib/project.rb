require 'ostruct'

class Project < OpenStruct
	class <<self
		(private_instance_methods-%w(initialize undef_method inspect)).each { |m| undef_method m }
		#undef_method "gem"
	end
end
