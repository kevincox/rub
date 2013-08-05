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

require 'rub/modules'

cwd = Pathname.new(__FILE__).realpath.dirname

`cd '#{cwd}'; git rev-parse --git-dir > /dev/null 2>&1`
ingit = $?.exitstatus == 0

if cwd.join('version-git.rb').exist? && ingit
	#puts 'Loading git'
	load cwd.join('version-git.rb').to_s
elsif cwd.join('version-generated.rb').exist?
	#puts 'Loading generated'
	load cwd.join('version-generated.rb').to_s
else
	raise "Couldn't fine version info!"
	exit 1
end
