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

require 'rub'

module R
	class << self
		attr_reader :ppersistant
		attr_reader :spersistant
	end
	
	ppersistfile = R::Env.project_cache + "persistant.marshal"
	if ppersistfile.exist? && R::CommandLine.cache
		@ppersistant = Marshal.load(File.new(ppersistfile, 'r').read)
	else
		@ppersistant = {}
	end
	
	END {
		if R::CommandLine.cache
			File.new(ppersistfile, 'w').write(Marshal.dump(@ppersistant))
		end
	}
	
	spersistfile = R::Env.global_cache + "persistant.marshal"
	if spersistfile.exist? && R::CommandLine.cache
		@spersistant = Marshal.load(spersistfile.read)
	else
		@spersistant = {}
	end
	
	END {
		if R::CommandLine.cache
			spersistfile.open('w').write(Marshal.dump(@spersistant))
		end
	}
end


