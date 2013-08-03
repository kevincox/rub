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

module R
	cattr_reader :targets
	
	@targets = {}
	@sources = {}
	
	def self.find_target(path)
		path = C.path(path)
		
		t = @targets[path]
	end
	def self.get_target(path)
		path = C.path(path)
		
		find_target(path) or @sources[path] ||= TargetSource.new(path)
	end
	
	class Target
		def input
			[]
		end
		def output
			[]
		end
		
		def register
			output.map do |f|
				f.expand_path
			end.each do |d|
				if R.targets[d]
					$stderr.puts "Warning: #{d} can be built two ways."
				end
				R.targets[d] = self
			end
		end
		
		def clean?
			false
		end
		
		def hash
			Digest::SHA1.digest(
				(
					output.map{|f| Digest::SHA1.file(f).to_s } +
					['-'] +
					input .map{|i| R::get_target(i).hash     }
				).join
			)
		end
		
		def build
			case @built
				when :built
					return
				when :started
					$stderr.puts "Warning: Circular dependency involving #{output.join(', ')}"
					return
			end
			@built = :started
		
			input.map do |f|
				Pathname.new(f).expand_path
			end.map do |f|
				[f, R.get_target(f)]
			end.each do |f, i| 
				#puts "Building #{f}"
				i.build
			end
			
			@built = :built
		end
	end
	
	class TargetSmart < Target
		attr_reader :input, :output
	
		def initialize
			@input  = []
			@output = []
		end
		
		def clean
			output.all?{|f| f.exist?} or return
			
			 R::ppersistant["Rub.Target.#{@output.sort.join('\0')}"] = hash
		end
		
		def clean?
			output.all?{|f| f.exist?} and R::ppersistant["Rub.Target.#{@output.sort.join('\0')}"] == hash
		end
	end
	
	class TargetSource < Target
		attr_reader :output
		
		def initialize(p)
			@output = [p]
		end
		
		def hash
			@hashcache ||= Digest::SHA1.file(output[0]).to_s
		end
		
		def build
			if not output[0].exist?
				#p self
				$stderr.puts "Error: source file #{output[0]} does not exist!"
				exit 1
			end
		end
	end
end
