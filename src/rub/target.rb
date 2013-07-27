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

module Rub
	class << self
		attr_accessor :targets
	end
	@targets = {}
	
	class Target
		
		attr_accessor :in, :out
		
		def initialize
			@in = []
			@out = []
		end
		
		def register
			@out.map!{|f| f.expand_path}
		
			@out.each{|d| Rub.targets[d] = self }
		end
		
		def clean
			@out.all?{|f| f.exist?} or return
			
			 Rub::ppersistant["Rub.Target.#{@out.sort.join('\0')}"] = hash
		end
		
		def clean?
			@out.all?{|f| f.exist?} and Rub::ppersistant["Rub.Target.#{@out.sort.join('\0')}"] == hash
		end
		
		def hash
			Digest::SHA1.digest(
				[@out, @in].map do |s|
					s.map{|f| Digest::SHA1.file(f).to_s }.join
				end.join
			)
		end
		
		def build
			@in.map!{|f| f.expand_path}
			
			@in.map{|f| [f, Rub.targets[f]]}.each do |f, i| 
				if not i and not f.exist?
					$stderr.puts "Error: can't build required target #{f}.  Don't know how."
				elsif i
					i.build
				end
			end
		end
	end
end
