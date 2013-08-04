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

# Environment Information
module R::Env
	# @!attribute [r] self.cmd_dir
	#   @return [Pathname] The directory from which rub was executed.
	cattr_accessor :cmd_dir
		
	# @!attribute [r] self.global_cache
	#   @return [Pathname] The global cache directory.
	cattr_reader :global_cache
	
	@cmd_dir = Pathname.pwd
	
	# @private
	def self.find_src_dir
		d = @cmd_dir
		while not (d+'root.rub').exist?
			d = d.parent
			
			if d.root?
				$stderr.puts('root.rub not found.  Make sure you are in the source directory.')
				exit 1
			end
		end
		
		d
	end
	private_class_method :find_src_dir

	# @return [Pathname] The directory from which rub was executed.
	def self.src_dir
		@src_dir ||= find_src_dir
	end
	
	# @return [Pathname] The build output directory.
	def self.out_dir
		@out_dir ||= @src_dir + 'build/'
	end
	
	@global_cache = Pathname(Dir.home())+".cache/rub/cache/"
	
	# @return [Pathname] The project cache directory.
	def self.project_cache
		@out_dir + "cache/"
	end
end
