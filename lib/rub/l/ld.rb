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

# Linker Library
module L::LD
	# @!scope class
	# All available linkers.
	# @return [Hash{Symbol=>Linker}]
	cattr_reader   :linkers
	
	@linkers = {}
	@prefered_linker = nil

	# A set of options for controlling the build.
	class Options
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
		cattr_reader   :library_dirs
		
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
		
		# Optimization level
		#
		# Override the global optimization level.
		#
		# @return (see optimize)
		# @see optimize
		attr_accessor  :optimize
		
		# Library search path.
		#
		# Override the global library search path.
		#
		# @return (see library_dirs)
		# @see library_dirs
		attr_reader    :library_dirs
		
		# Static linking.
		#
		# Override the global static linking setting.
		#
		# @return (see static)
		# @see static
		attr_accessor  :static
		
		# Linker arguments.
		#
		# Override the global linker arguments.
		#
		# @return (see args)
		# @see args
		attr_accessor  :args
		
		def initialize
			@optimize     = Options.optimize
			@static       = Options.static
			@library_dirs = Options.library_dirs.dup
			@args         = Options.args.dup
		end
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
		# @param options [Options] An options object.
		# @return [Set<Pathname>] The output file.
		def self.link_command(files, libs, out, format: :exe, options: Options)
			raise NotImplementedError
		end
		
		# Perform a link.
		#
		# @param (see link_command)
		# @return [R::Command] the process that linked the file.
		def self.do_link(files, libs, out, format: :exe, options: Options)
			c = R::Command.new(link_command(files, libs, out, format: :exe, options: options))
			c.run
			c
		end
		
		# Peform a test link.
		#
		# @param (see link_command)
		# @return [true,false] true if the link succeeded.
		def self.test_link(files, libs, format: :exe, options: Options)
			c = do_link(files, libs, File::NULL, format: :exe, options: options)
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
		def self.find_lib(name, options: Options)
			whereis = C::find_command('whereis') or return nil
			
			c = R::Command.new [whereis, '-b', "lib#{name}"]
			c.run or return nil
			
			l = c.stdout.split.drop(1).keep_if do |l|
				options.static ? l.end_with?('.a') : l.end_with?('.so')
			end
			
			l[0]
		end
	end
	
	R::Tool.load_dir(Pathname.new(__FILE__).realpath.dirname+"ld/linker/")
	
	@linkers.keep_if do |n, l|
		l.available? or next false
	end
	
	D[:l_ld_linker].map! {|l| l.to_sym}
	@prefered_linker = D[:l_ld_linker].find {|l| @linkers.has_key? l}
	
	# Return a linker object.
	#
	# @param name [Symbol,nil,Object] The name of the linker.
	# @return [Linker] The linker identified by +name+ or nil.  If a non-symbol
	#                  non-nil object is passed by in name it is returned
	#                  without ensuring it is a liker.
	def self.linker(name=nil)
		name ||= @prefered_linker
	
		if name.is_a? Symbol
			@linkers[name]
		else
			name
		end
	end
	
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
	# @param options [Options] An options object.
	# @return [Pathname] The output file.
	def self.link(src, libs, name, format: :exe, linker: nil, options: Options)
		src  = R::Tool.make_set_paths src
		libs = R::Tool.make_set libs
		
		linker = linker linker
		
		libfs = libs.map {|l| linker.find_lib l or raise "Can't find library #{l}."}
		
		out = linker.full_name name, format
		out = R::Env.out_dir + 'l/ld/' + out
		
		C::generator(src+libfs, linker.link_command(src, libs, out, format: format, options: options), out)
		
		out
	end
end
