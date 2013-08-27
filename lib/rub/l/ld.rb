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

# Linker Library
module L::LD
	# @!scope class
	# All available linkers.
	# @return [Hash{Symbol=>Linker}]
	cattr_reader :linkers
	@linkers = {}
	
	# @!scope class
	# The linker being used.
	# @return [Linker]
	cattr_accessor :linker
	
	# @!scope class
	# Default optimization level.
	#
	# This takes one of four optimization levels.  The actual optimization
	# done is linker dependant.  For example, some linker may not have
	# any optimization so all levels will be equivalent.
	#
	# One of the following:
	# [+:none+] Perform no optimization.  This should be fast and debuggable.
	# [+:some+] Perform light optimization that is pretty fast.
	# [+:full+] Perform a high level of optimization producing a fast binary.
	#           this may considerably slow down compilation.
	# [+:max+]  Perform all available optimizations.  These may be
	#           experimental and very slow.
	#
	# This value defaults to +:full+ if +D:debug+ is set, otherwise +:none+.
	#
	# @return [Symbol]
	cattr_accessor :optimize
	
	# @!scope class
	# A list of library search directories to be added to the default search
	# path.
	#
	# These paths are searched in order.
	#
	# @return [Array<Pathname>]
	cattr_accessor :library_dirs
	
	# @!scope class
	# The default for static linking.
	#
	# If set to true shared libraries won't be used.  Defaults to false.
	#
	# @return [true,false]
	cattr_accessor :static
	
	# @!scope class
	# Default arguments to add to the linker command.
	#
	# @note This adds raw arguments to the linker command and is a quick n'
	#       easy way to reduce portability.  If you can, use the other
	#       options provided by this class in order to maintain portability.
	#
	# @return [Array<String>] A list of arguments to add.
	cattr_accessor :args
	
	@optimize = D[:debug] ? :none : :full
	@library_dirs = []
	@static = false
	@args = []
	
	def self.set_linker(name)
		self.linker = linkers[name]
	end

	# An abstraction for a linker.
	module Linker
		# The name of the linker.
		# @return [Symbol]
		def self.name
			:default
		end
		
		# Is this linker available on this system?
		#
		# @return [true,false] true if the linker is available.
		def self.available?
			false
		end
		
		# Return the linker's builtin library path.
		#
		# @return [Array<Pathname>]
		def self.builtin_library_path
			@builtin_library_path ||= [
				'/lib/',
				'/usr/lib/',
				'/usr/local/lib/',
				'~/.local/lib/',
			].map do |l|
				C.path(l)
			end.uniq
		end
		
		# Return the path which to search for libraries.
		#
		# @return [Array<Pathname>]
		def self.library_path(opt)
			opt.library_dirs + builtin_library_path
		end
		
		# Generate a command to perform the link.
		#
		# @param files   [Set<Pathname,String>,Array<Pathname,String>,Pathname,String]
		#                The object files to link.
		# @param libs    [Set<String>,Array<String>,String] Libraries to link with.
		# @param out     [Pathname,String] The output file.
		# @param format  [Symbol] The type of output to produce.
		#                One of:
		#                [+:exe+]    An executable binary.
		#                [+:shared+] A shared library.
		# @param opt [Options] An options object.
		# @return [Set<Pathname>] The output file.
		def self.link_command(opt, files, libs, out, format)
			raise NotImplementedError
		end
		
		# Perform a link.
		#
		# @param (see link_command)
		# @return [R::Command] the process that linked the file.
		def self.do_link(opt, files, libs, out, format)
			c = R::Command.new(link_command(opt, files, libs, out, format))
			c.run
			c
		end
		
		# Peform a test link.
		#
		# @param (see link_command)
		# @return [true,false] true if the link succeeded.
		def self.test_link(opt, files, libs, format)
			c = do_link(opt, files, libs, File::NULL, format)
			#p c.success?, c.stdin, c.stdout, c.stderr
			c.success?
		end
		
		@@name_map = {
			exe:    '%s',
			shared: 'lib%s.so',
			static: 'lib%s.a',
		}
		
		# Generate an appropriate name.
		#
		# @param base [String] The basename.
		# @param type [Symbol] The output format.
		# @return [String] A suitable name for the output type on the
		#                  current machine.
		def self.full_name(base, type)
			@@name_map[type] % base
		end
		
		# Locate a library.
		#
		# Locates the library that would be used with when linking.
		#
		# @param name [String] The basename of the library.
		# @param options [Options] The options to use when linking.
		# @return [Pathname] The path to the library.
		def self.find_lib(opt, name)
			sp = library_path(opt)
			name = full_name name, (opt.static ? :static : :shared)
			
			sp.each do |d|
				l = d + name
				
				l.exist? and return l
			end
		end
	end
	
	R::Tool.load_dir(Pathname.new(__FILE__).realpath.dirname+"ld/linker/")
	@linkers.keep_if do |n, l|
		l.available? or next false
	end
	
	D[:l_ld_linker].map! {|l| l.to_sym}
	@linker = D[:l_ld_linker].find {|l| @linkers.has_key? l}
	@linker = @linkers[@linker]
	
	# Link object files.
	#
	# @param src     [Set<Pathname,String>,Array<Pathname,String>,Pathname,String]
	#                The object files to link.
	# @param libs    [Set<String>,Array<String>,String] Libraries to link with.
	# @param name    [Pathname,String] The basename of the output file.
	# @param format  [Symbol] The type of output to produce.
	#                One of:
	#                [+:exe+]    An executable binary.
	#                [+:shared+] A shared library.
	# @param linker  [Symbol] The linker to use.  If nil, use the default.
	# @return [Pathname] The output file.
	def self.link(src, libs, name, format: :exe)
		src  = R::Tool.make_set_paths src
		libs = R::Tool.make_set libs
		
		libfs = libs.map {|l| linker.find_lib(self, l) or raise "Can't find library #{l}."}
		
		out = linker.full_name name, format
		out = R::Env.out_dir + 'l/ld/' + C.unique_segment(src, libs, self) + out
		
		C::generator(src+libfs, linker.link_command(self, src, libs, out, format), out)
		
		out
	end
	
	def self.initialize_copy(s)
		super
		
		self.library_dirs = s.library_dirs.dup
	end
end
