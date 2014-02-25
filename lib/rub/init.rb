#! /usr/bin/env ruby

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

##### These libraries are guaranteed to be loaded.
require 'pathname'
require 'set'
require 'pp'
require 'thread'
require 'digest/sha1'

require 'sysexits'
require 'facter'
require 'xdg'

# This is first so we modify all of our classes.
# Traces all calls.
'
class Object
	def self.method_added name
		return if name == :initialize
		return if @__last_methods_added && @__last_methods_added.include?(name)
		
		with = :"#{name}_with_before_each_method"
		without = :"#{name}_without_before_each_method"
		
		@__last_methods_added = [name, with, without]
		define_method with do |*args, &block|
			puts "#{self.class}##{name}"
			pp args, &block
			puts "calling..."
			
			r = send without, *args, &block
			
			puts "#{self.class}##{name} returned"
			
			r
		end
		alias_method without, name
		alias_method name, with
		@__last_methods_added = nil
	end
end
#'

##### Load the namespaces.
require_relative 'd'
require_relative 'r'
require_relative 'l'
require_relative 'c'

# Odd jobs.
require_relative 'dirs'
require_relative 'help'

##### Add the first two scripts.
R::I::Runner.do_file(R::Env.src_dir+"root.rub")
R::I::Runner.do_file(R::Env.cmd_dir+"dir.rub")

##### Add default target if necessary.
ARGV.empty? and ARGV << ':all'

cont = true

while cont
	##### Build requested targets.
	ARGV.each do |t|
		t = if t =~ /^:[^\/]*$/ # Is a tag.
			t[1..-1].to_sym
		else
			C.path(t)
		end
		R::get_target(t).build
	end
	
	if R::I::CommandLine.watch
		puts "Build complete."
		
		changed = Set.new
		while true
			tosleep = 0
			R.oodtargets_mutex.synchronize do
				ood = R.oodtargets
				changed.merge ood
				
				if changed.empty? # Nothing new.
					R.oodtargets_cond.wait R.oodtargets_mutex # So wait for something.
				elsif ood.any? # Batch changes a bit.
					tosleep = 0.5
				else
					tosleep = 0 # Rebuild.
				end
			end
			
			if tosleep != 0
				sleep tosleep
			else
				break
			end
		end
		
		changed.each {|t| self.find_target(t).invalidate }
	else
		cont = false
	end
end

