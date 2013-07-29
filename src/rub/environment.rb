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

require 'pathname'

module R
	module Env
		cattr_accessor :cmd_dir
		cattr_accessor :out_dir
			
		cattr_reader :global_cache
		
		@cmd_dir = Pathname.pwd
		
		def self.src_dir
			@src_dir and return @src_dir
		
			@src_dir = @cmd_dir
			while not (@src_dir+'root.rub').exist?
				@src_dir = @src_dir.parent
				
				if @src_dir.root?
					$stderr.puts('root.rub not found.  Make sure you are in the source directory.')
					exit 1
				end
			end
			
			@out_dir = @src_dir + 'build/'
			
			@src_dir
		end
		
		@global_cache = Pathname(Dir.home())+".cache/rub/cache/"
		def self.project_cache
			@out_dir + "cache/"
		end
	end
end
