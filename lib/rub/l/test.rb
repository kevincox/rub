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

require 'singleton'
require 'stringio'

require 'minitest'
require 'minitest/spec'
require 'minitest/mock'

class Minitest::Runnable
	@@rub_oldinherited = method :inherited
	def self.inherited klass
		L::Test.make_test klass
		
		@@rub_oldinherited.call klass
	end
	
	# Add a dependency
	#
	# Add a dependency to the test.  It will be available before the test is
	# run.
	#
	# @param d [Set<Pathname,String>,Array<Pathname,String>,Pathname,String]
	#          The dependencies.
	def self.rub_add_dependency(d)
		d = R::Tool.make_set_paths d
		
		@rub_deps ||= Set.new
		
		@rub_deps.merge d
	end
	
	# Get tests dependencies.
	#
	# @private
	def self.rub_get_dependancies
		@rub_deps || Set.new
	end
end

# Testing.
#
# This testing is powered by Minitest.  Look up the docs for that.
#
# All test are defined as regular Minitest tests and they will be automatically
# picked up and have tags created for them.
#
# When defining the test class there will be an additional method
# {Minitest::Runnable#rub_add_dependency} that will allow the test to depend
# on any target.  Therefore you can ensure that what you are testing has been
# built.
#
# @example Defining dependencies.
#
#   Minitest::Test
#   	rub_add_dependancy $myexe # Ensure $myexe will be available when test are run.
#   	
#   	def test_help
#   		c = R::Command.new [$myexe, '--help']
#   		c.run
#   		
#   		assert c.success?, 'Help exited with a good status code'
#   	end
#   end
#
module L::Test
	C.tag(:test)
	
	class TargetTestCase < R::Target
		def input
			pp @klass.rub_get_dependancies
			@klass.rub_get_dependancies
		end
	
		def output
			Set[@tag]
		end
	
		def initialize(klass, t)
			super()
			
			@tag = t.to_sym
			@klass = klass
			
			C.tag(:test).require(@tag)
			
			register
		end
		
		def build_self
			out = StringIO.new("", "w")
		
			options = {
				io:      out,
				verbose: true
			}

			reporter =  Minitest::CompositeReporter.new
			reporter << Minitest::ProgressReporter.new(options[:io], options)
			reporter << Minitest::SummaryReporter .new(options[:io], options)

			reporter.start
			Minitest.__run reporter, options
			reporter.report
			
			bs = R::BuildStep.new
			bs.desc = "Running test case :#{@tag}"
			bs.status = reporter.passed? ? 0 : 1
			bs.out = out.string
			bs.print
		end
	end
	
	def self.make_test(klass)
		@tests ||= {}
	
		sklass = klass.to_s
		if sklass =~ /^Test/ 
			name = sklass
			         .gsub(/(?<=[a-z0-9])([A-Z])/, '-\1')
			         .gsub(/(?<=[^0-9])([0-9])/, '-\1')
			         .gsub('_', '-')
			         .downcase.to_sym
			#pp name
			
			@tests[name] ||= TargetTestCase.new(klass, name)
		end
	end
end
