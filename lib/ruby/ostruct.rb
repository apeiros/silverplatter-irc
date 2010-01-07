#--
# Copyright 2007 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



require 'ostruct'



class OpenStruct
	def self.with(&block)
		struct = new
		struct.instance_eval(&block)
		struct
	end

	# Get the field by its name, faster than #send and with
	# dynamic field names more convenient.
	def [](field)
		@table[field.to_sym]
	end
	
	# Assign a field by its name, faster than #send and with
	# dynamic fields more convenient
	def []=(field,value)
		new_ostruct_member(field)
		@table[field.to_sym] = value
	end
	
	# Get a copy of the table with the members.
	def to_hash
		@table.dup
	end

	# Get the internal hash-table.
	def __hash__
		@table
	end
end
