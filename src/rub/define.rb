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

require 'rub/environment'

module D
	@@map = {}
	
	def self.define(k, v=nil)
		if v == nil
			k, f, v = k.partition '='
			
			if k.end_with?('+')
				return push(k[0..-2], v)
			end
		end
		
		k = k.to_sym
		
		if f == ""
			v = true
		end
		
		@@map[k] = v
	end
	
	def self.push(k, v=nil)
		if v == nil
			k, f, v = k.partition '='
			
			if k.end_with?('+')
				k = k[0..-2]
			end
		end
		
		k = k.to_sym
		
		if f == ''
			v = true
		end
		
		@@map[k].is_a?(Array) or @@map[k] = []
		
		@@map[k].push(v)
	end
	
	def self.[] (k)
		@@map[k]
	end
	
	def self.map
		return @@map
	end
	
	def self.fromFile(fn)
		File.open(fn) {|f| f.each_line {|l| define(l.chomp) } }
	end
	
	def self.resolve_path(k)
		@@map[k] or return nil
	
		@@map[k] = Pathname.new(@@map[k]).expand_path(Rub::Env.cmd_dir)
	end
end
