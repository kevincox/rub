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
		::L::Test.make_test klass
		
		@@rub_oldinherited.call klass
	end
	
	# The Rub target, this is set automatically.
	#
	# @return [R::Target]
	cattr_accessor :rub_target
	
	# Add a dependency
	#
	# Add a dependency to the test.  It will be available before the test is
	# run.
	#
	# @param d [Set<Pathname,String>,Array<Pathname,String>,Pathname,String]
	#          The dependencies.
	def self.rub_require(d)
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
# {Minitest::Runnable#rub_require} that will allow the test to depend
# on any target.  Therefore you can ensure that what you are testing has been
# built.
#
# @example Defining dependencies.
#
#   class TestPath < Minitest::Test
#   	rub_require $myexe # Ensure $myexe will be available when test are run.
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
	
	class Reporter < Minitest::AbstractReporter
		def initialize(opt = {})
			@passed = true
			
			@io = opt[:io] || $stdout
		end
	
		##
		# Starts reporting on the run.
		def start
		end
		
		##
		# Record a result and output the Runnable#result_code. Stores the
		# result of the run if the run did not pass.
		def record(r)
			pres = if r.skipped?
				"\e[34;1mSKIP\e[0m"
			elsif r.passed?
				"\e[32;1mPASS\e[0m"
			else
				"\e[31;1mFAIL\e[0m"
			end
			
			@io.puts "[#{pres}] #{r.class}##{r.name}"
		end
		
		##
		# Outputs the summary of the run.
		def report
		end
		
		##
		# Did this run pass?
		def passed?
			@passed
		end
	end
	
	class TargetTest < R::Target
		def input
			Minitest::Runnable.runnables.map do |r|
				r.rub_target
			end.compact.map do |t|
				t.input.to_a
			end.flatten.to_set
		end
	
		def output
			Set[:test]
		end
	
		def initialize
			super()
			
			register
		end
		
		def run_tests(reporter, options)
			Minitest::Runnable.runnables.each do |r|
				r.rub_target or next
				
				r.rub_target.run_tests reporter, options
			end
		end
		
		def build_self
			out = StringIO.new("", "w")
		
			options = {
				io:      out,
				verbose: true,
			}

			reporter = Minitest::CompositeReporter.new
			reporter << Minitest::SummaryReporter.new(options[:io], options)
			
			reporter.start
			out.string = '' # We don't want the start text.
			
			run_tests reporter, options
			reporter.report
			
			bs = R::BuildStep.new
			bs.desc = "Test Results"
			bs.status = reporter.passed? ? 0 : 1
			bs.out = out.string
			bs.print
		end
	end
	TargetTest.new # Create :test
	
	class TargetTestCase < TargetTest
		def input
			@klass.rub_get_dependancies
		end
	
		def output
			Set[@tag]
		end
	
		def initialize(klass, t)
			@tag = t.to_sym
			@klass = klass
			
			klass.rub_target = self
			
			super()
		end
		
		def run_tests(reporter, options)
			out = StringIO.new("", "w")
			options = {
				io:      out,
				verbose: true
			}
			pr = Reporter.new(options)
			reporter << pr
			
			@klass.run reporter, options
			
			reporter.reporters.delete pr
			
			bs = R::BuildStep.new
			bs.desc = "Running test case :#{@tag}"
			bs.out  = out.string
			bs.status = pr.passed? ? 0 : 1
			bs.print
		end
	end
	
	class TargetTestExecutable < R::TargetGenerator
		def build
			build_dependancies
			
			R::run(@cmd[0], "#@action #{@output.to_a.join", "}") or exit 1
		end
	end
	
	def self.external(cmd, name)
		t = TargetTestExecutable.new
		t.add_cmd cmd
		t.output << name
		
		t.register
	end
end
