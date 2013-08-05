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

require 'digest/sha1'
require 'pathname'
require 'set'

module R
	# All targets.
	#
	# This should only be used for debugging.  Use {find_target}, {get_target}
	# and {set_target} instead.
	#
	# @return [Hash{Pathname,Symbol=>Target}]
	cattr_reader :targets
	
	@targets = {}
	@sources = {}
	
	# Find a target.
	#
	# Returns a target for +path+ or nil.
	#
	# @param path [Pathname,String] The path of the target.
	# @return [Target,nil] The target.
	def self.find_target(path)
		path = Pathname.new(path).expand_path unless path.is_a? Symbol
		@targets[path] || @sources[path]
	end
	
	# Get a target.
	#
	# This function get's an existing target if it exists or returns a new
	# source target if there is no existing target to build it.
	#
	# @param path [Pathname,String] The path of the target.
	# @return [Target,TargetSource]
	def self.get_target(path)
		path = Pathname.new(path).expand_path unless path.is_a? Symbol
		
		find_target(path) or @sources[path] ||= TargetSource.new(path)
	end
	
	# Set a target to a path.
	#
	# This function registers +target+ as a way to build +path+.
	#
	# @param path [Pathname,String] The path that is build by the target.
	# @param target [Target] The target that builds +path+.
	# @return [void]
	#
	# @see Target#register.
	def self.set_target(path, target)
		if find_target(path)
			$stderr.puts "Warning: #{path} can be built two ways."
		end
		path = Pathname.new(path).expand_path unless path.is_a? Symbol
		@targets[path] = target
	end
	
	# The base target class.
	#
	# It has simple building logic and a way to register targets.  All
	# targets should inherit from this class.
	class Target
		# Inputs
		#
		# @return [Set<Pathname>] The inputs this target depends on.
		def input
			Set.new
		end
		
		# Outputs
		#
		# @return [Set<Pathname>] The outputs this target creates.
		def output
			Set.new
		end
		
		# Description.
		#
		# Shown for :help.
		# @return [String,nil]
		def description
			nil
		end
		
		# Register this target.
		#
		# Registers this target as building it's {#output}s.
		#
		# @return [void]
		def register
			output.each do |d|
				R.set_target(d, self)
			end
		end
		
		# Is this target up to date?
		def clean?
			false
		end
		
		# Return a hash of this target.
		#
		# This hash should represent a unique build environment and change if
		# anything in that environment does.  This includes, but is not limited
		# to:
		# - Input files.
		# - Output files.
		# - Build commands.
		#
		# @return [String] the hash.
		def hash_contents
			Digest::SHA1.digest(
				(
					output.map{|f| Digest::SHA1.file(f).to_s      } +
					['-'] +
					input .map{|i| R::get_target(i).hash_contents }
				).join
			)
		end
		
		# Build the inputs.
		def build_dependancies
			input.each{|i| R::get_target(i).build }
		end
		private :build_dependancies
		
		# Build this target.
		#
		# This should be overridden if {#build} itself is not overridden.
		
		# @return [void]
		def build_self
			raise "#build_self not implemented in #{self.class}."
		end
		private :build_self
		
		# Build.
		#
		# This is a simple build method.  It calls {#build_dependancies} then
		# {#build_self}.  Either or both of these methods can be overwritten to
		# customize the build or this function can be overwritten to have more
		# control.
		# 
		# @return [void]
		def build
			build_dependancies
			build_self
			
			nil
		end
	end
	
	# Target with additional functionality.
	class TargetSmart < Target
		attr_reader :input, :output
	
		def initialize
			@input  = Set.new
			@output = Set.new
		end
		
		# Mark target as clean.
		#
		# @return [void]
		def clean
			output.all?{|f| f.exist?} or return
			
			 R::ppersistant["Rub.Target.#{@output.sort.join('\0')}"] = hash_contents
		end
		
		# Is this target clean?
		#
		# @return [true,false] True if this target is up-to-date.
		def clean?
			output.all?{|f| f.exist?} and R::ppersistant["Rub.Target.#{@output.sort.join('\0')}"] == hash_contents
		end
	end
	
	# A target for existing sources.
	class TargetSource < Target
		attr_reader :output
		
		def initialize(p)
			@src    = p
			@output = Set[p]
		end
		
		def hash_contents
			@hashcache ||= Digest::SHA1.file(@src).to_s
		end
		
		def build
			if not @src.exist?
				#p self
				$stderr.puts "Error: source file #{@src} does not exist!"
				exit 1
			end
		end
	end
end
