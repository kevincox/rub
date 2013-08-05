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

# Functions for running build scripts.
module R::Runner
	@@loaded = {}

	# Execute a file.
	#
	# Runs a script if it hasn't been run already.
	#
	# @param f [Pathname] The file to run.
	# @return [void]
	def self.do_file(f)
		if @@loaded[f]
			return
		end
	
		if not f.exist?
			$stderr.puts "\"#{f}\" is not readable!"
			Sysexits.exit :noinput
		end
		
		@@loaded[f] = true
		
		Dir.chdir f.dirname
		load f.to_s
	end
end

module C
	# Add a directory to the build.
	#
	# This will run the "dir.rub" file in that directory synchronously.  Any
	# values that that directory defines will be available when this call
	# returns.
	#
	# This function only runs scripts once, if the script has already run this
	# function will return success without running the script, and as the script
	# has already been run the exported values should be available.
	def self.add_dir(dir)
		dir = C.path(dir)
		
		if not dir.directory?
			raise "\"#{dir}\" is not a directory!"
		end
		
		dir += 'dir.rub'
		if not dir.exist?
			raise "\"#{dir}\" does not exist!"
		end
		dir = dir.realpath
		
		R::Runner.do_file(dir)
	end
end
