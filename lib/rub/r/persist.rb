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

module R
	# @!attribute [r] self.ppersistant
	#   @return [Hash] The project cache.
	cattr_reader :ppersistant
	
	# @!attribute [r] self.spersistant
	#   @return [Hash] The system cache.
	cattr_reader :spersistant
	
	ppersistfile = R::Env.project_cache + "persistant.marshal"
	if ppersistfile.exist? && R::I::CommandLine.cache
		@ppersistant = Marshal.load(File.new(ppersistfile, 'r').read)
	else
		@ppersistant = {}
	end
	
	END {
		File.new(ppersistfile, 'w').write(Marshal.dump(@ppersistant))
	}
	
	spersistfile = R::Env.global_cache + "persistant.marshal"
	if spersistfile.exist? && R::I::CommandLine.cache
		@spersistant = Marshal.load(spersistfile.read)
	else
		@spersistant = {}
	end
	
	END {
		spersistfile.open('w').write(Marshal.dump(@spersistant))
	}
	
	# Clear the system cache.
	def self.clear_system_cache
		@spersistant.clear
	end
	# Clear the project cache.
	def self.clear_project_cache
		@ppersistant.clear
	end
	# Clear all caches.
	def self.clear_cache
		clear_system_cache
		clear_project_cache
	end
end


