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

require 'sysexits'

require 'rub/environment'

module R::Runner
	@@loaded = {}

	def self.doFile(f)
		fs = f.to_s
		if @@loaded[fs]
			return
		end
	
		if not f.exist?
			$stderr.puts "\"#{f}\" is not readable!"
			Sysexits.exit :noinput
		end
		
		@@loaded[fs] = true
		
		Dir.chdir f.dirname
		load fs
	end
end

module C
	def self.addDir(dir)
		dir = Pathname.new(dir)
		
		if not dir.directory?
			raise "\"#{dir}\" is not a directory!"
		end
		
		dir += 'dir.rub'
		if not dir.exist?
			raise "\"#{dir}\" does not exist!"
		end
	
		R::Runner.doFile(dir)
	end
end
