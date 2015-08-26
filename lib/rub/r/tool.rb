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

require 'thread/pool'
require 'fssm'
require 'valid_array'

class Module
	# Class attribute reader.
	#
	# @see attr_reader
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
	# Class attribute writer.
	#
	# @see attr_writer
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
	# Class attribute accessor.
	#
	# @see attr_accessor
	def cattr_accessor(*name)
		cattr_reader(*name)
		cattr_writer(*name)
	end
end

# From: http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-list/43424
class Object
  # Recursively clone an object.
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

# Utility functions aimed at library writers.
module R::Tool
	# Make argument an array.
	#
	# Turns a single item into an array or copies an array.
	#
	#   R::Tool.make_array  :item  #=> [:item]
	#   R::Tool.make_array [:item] #=> [:item]
	#   
	#   a = ["string1", "string2"]
	#   b = R::Tool.make_array a   #=> ["string1", "string2"]
	#   a.equal? b                 #=> false
	#   a[0].equal? b[0]           #=> true
	#   a[1].equal? b[1]           #=> true
	#   
	def self.make_array(a)
		if a.respond_to? :to_a
			a.to_a.dup
		else
			[a]
		end
	end
	# Make argument a set.
	#
	# @see make_array   
	def self.make_set(a)
		make_array(a).to_set
	end
	
	# Make argument an array of Pathname objects.
	#
	# @see make_array
	#
	#   a = C.path('root.rub')          #=> #<Pathname:root.rub>
	#   b = 'dir.rub'                   #=> "dir.rub"
	#   R::Tool.make_array_paths a      #=> [#<Pathname:/path/to/root.rub>]
	#   R::Tool.make_array_paths [a]    #=> [#<Pathname:/path/to/root.rub>]
	#   R::Tool.make_array_paths [a, b] #=> [#<Pathname:/path/to/root.rub>, #<Pathname:/path/to/dir.rub>]
	#   R::Tool.make_array_paths b      #=> [#<Pathname:/path/to/dir.rub>]
	def self.make_array_paths(a)
		make_array(a).map do |p|
			C.path(p)
		end
	end
	
	# Make argument a Set of Pathname objects.
	#
	# @see make_array_paths
	def self.make_set_paths(a)
		make_array_paths(a).to_set
	end
	
	# load every script in the directory +d+.
	def self.load_dir(d)
		d = C.path(d)
		
		d.children.each {|i| load i}
	end
	
	class PathArray < Array
		extend ValidArray
		
		def self.validate(item)
			C.path item
		end
	end
	
	class Blocker
		def initialize
			@queue = Queue.new
		end
		
		def notify err
			@queue << err
		end
		
		def wait
			err = @queue.pop
			raise err if err
		end
	end
	
	Thread.abort_on_exception = true
	Thread::Pool.abort_on_exception = true
	
	cattr_reader :fsmonitor
	@fsmonitor = FSSM::Monitor.new
	Thread.new { @fsmonitor.run }
	
	D[:r_jobs] ||= Facter.value('processors')['count']
	puts "Using #{D:r_jobs} simultaneous jobs."
	@threadpool = Thread.pool D[:r_jobs]
	cattr_accessor :threadpool
end
