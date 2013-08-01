# Copyright 2013 Kevin Cox

################################################################################
#                                                                              #
#  This software is provided 'as-is', without any express or implied           #
#  warranty. In no event will the authors be held liable for any damages       #
#  arising from the use of this software.                                      #
#                                                                              #
#  Permission is granted to anyone to use this software for any purpose,       #
#  including commercial applications, and to alter it and redistribute it      #
#  freely, subject to the following restrictions:                              #
#                                                                              #
#  1. The origin of this software must not be misrepresented; you must not     #
#     claim that you wrote the original software. If you use this software in  #
#     a product, an acknowledgment in the product documentation would be       #
#     appreciated but is not required.                                         #
#                                                                              #
#  2. Altered source versions must be plainly marked as such, and must not be  #
#     misrepresented as being the original software.                           #
#                                                                              #
#  3. This notice may not be removed or altered from any source distribution.  #
#                                                                              #
################################################################################

require 'rub'

class Module
	def cattr_reader(*name)
		name.each do |n|
			class_eval(<<-EOS, __FILE__, __LINE__ + 1)
unless defined? @@#{n}
	@@#{n} = nil
end

def self.#{n}
	@#{n}
end
EOS
		end
	end
	def cattr_writer(*name)
		name.each do |n|
			class_eval(<<-EOS, __FILE__, __LINE__ + 1)
unless defined? @@#{n}
	@#{n} = nil
end

def self.#{n}=(v)
	@#{n} = v
end
EOS
		end
	end
	def cattr_accessor(*name)
		cattr_reader(*name)
		cattr_writer(*name)
	end
end

# From: http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-list/43424
class Object
  def deep_clone
    return @deep_cloning_obj if @deep_cloning
    @deep_cloning_obj = clone
    @deep_cloning_obj.instance_variables.each do |var|
      val = @deep_cloning_obj.instance_variable_get(var)
      begin
        @deep_cloning = true
        val = val.deep_clone
      rescue TypeError
        next
      ensure
        @deep_cloning = false
      end
      @deep_cloning_obj.instance_variable_set(var, val)
    end
    deep_cloning_obj = @deep_cloning_obj
    @deep_cloning_obj = nil
    deep_cloning_obj
  end
end

module R::Tool
	def self.make_array(a)
		if a.is_a? Array
			a.dup
		else
			[a]
		end
	end
	
	def self.make_array_paths(a)
		if a.is_a? Array
			a.dup
		else
			[a]
		end.map do |p|
			Pathname.new p
		end
	end
	
	def self.load_dir(d)
		d = Pathname.new(d)
		
		d.children.each {|i| load i}
	end
end
