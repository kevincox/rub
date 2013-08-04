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

require 'tempfile'

require 'rub/l/ld'

# C Library
module L::C
	# @!scope class
	# All available compilers.
	# @return [Hash{Symbol=>Compiler}]
	cattr_reader   :compilers
	
	@compilers = {}
	@prefered_compiler = nil

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
		# Default optimization goal.
		#
		# This determines what the compiler should optimize for if it has the
		# option.
		#
		# One of the following:
		# [+:size+]  The compiler should focus on creating a small binary.
		# [+:speed+] The compiler should focus on creating a fast binary.
		#
		# @return [Symbol]
		cattr_accessor :optimize_for
		
		# @!scope class
		# Default debug symbols setting.
		#
		# This determines if the compiler should produce debugging symbols.
		#
		# @return [true,false]
		cattr_accessor :debug
		
		# @!scope class
		# Default profile symbols setting.
		#
		# This determines if the compiler should produce code suitable for
		# profiling.
		#
		# @return [true,false]
		cattr_accessor :profile
	
		# @!scope class
		# A list of directories to search for header files.
		#
		# These paths are searched in order.
		#
		# @return [Array<Pathname>]
		cattr_reader :include_dirs
		
		# @!scope class
		# A list of macros to define.  nil can be used to undefine a macro.
		#
		# @return [Hash{String=>String,true,nil}]
		cattr_reader :define
		
		@@debug = @@profile = !!D[:debug]
		@@optimize = @@debug ? :none : :full
		
		@@include_dirs = []
		@@define = {
			@@debug ? 'DEBUG' : 'NDEBUG' => true,
		}
		
		# Optimization level
		#
		# Override the global optimization level.
		#
		# @return (see optimize)
		# @see optimize
		attr_accessor :optimize
		
		# Optimization goal.
		#
		# Override the global optimization goal.
		#
		# @return (see optimize_for)
		# @see optimize_for
		attr_accessor :optimize_for
		
		# Debugging Symbols
		#
		# Override the global debugging settings.
		#
		# @return (see debug)
		# @see debug
		attr_accessor :debug
		
		# Profile setting.
		#
		# Override the global profiling setting.
		#
		# @return (see profile)
		# @see profile
		attr_accessor :profile
	
		# Include path.
		#
		# Override the global include path.
		#
		# @return (see include_dirs)
		# @see include_dirs
		attr_reader :include_dirs
		
		# Macro definitions.
		#
		# Override the global definitions list..
		#
		# @return (see define)
		# @see define
		attr_accessor :define
		
		def initialize
			@optimize     = @@optimize
			@optimize_for = @@optimize_for
			
			@debug   = @@debug
			@profile = @@profile
			
			@include_dirs = @@include_dirs.dup
			@define       = @@define.dup
		end
	end
	
	# An Abstraction over different compilers.
	module Compiler
		# The name of the compiler.
		#
		# @return [Symbol]
		def self.name
			:default
		end
		
		# If the compiler is available on the current system.
		#
		# @return [true,false]
		def self.available?
			false
		end
		
		# Return the preferred linker.
		#
		# Some compilers create objects that need to be linked with their
		# linker.  This allows the compiler to specify the linker is wishes to
		# be used.
		def self.linker
			nil
		end
		
		# Compile source files.
		#
		# @param src     [Set<Pathname,String>,Array<Pathname,String>,Pathname,String]
		#                The source files to link and generated headers.
		# @param obj     [Pathname,String] The path of the output file.
		# @param options [Options] An options object.
		# @return [Pathname] The output file.
		def self.compile_command(src, obj, options: Options.new)
			raise "Not implemented!"
		end
		
		# Compile a file.
		#
		# @param (see compile_command)
		# @return [R::Command] the process that compiled the file.
		def self.do_compile_file(f, obj, options: Options.new)
			compile_command(f, obj)
			c = R::Command.new(compile_command(f, obj, options: options))
			c.run
			c
		end
		
		# Compile a string.
		#
		# @param src     [Set<Pathname,String>,Array<Pathname,String>,Pathname,String]
		#                A string containing the complete source to compile.
		# @param obj     [Pathname,String] The path of the output file.
		# @param options [Options] An options object.
		# @return [R::Command] the process that compiled the string.
		def self.do_compile_string(str, obj, options: Options.new)
			f = Tempfile.new(['rub.l.c.testcompile', '.c'])
			f.write(str)
			f.close
			c = do_compile_file(f.path, obj, options: options)
			f.unlink
			c
		end
		
		# Peform a test compile.
		#
		# @param (see do_compile_file)
		# @return [true,false] true if the compilation succeeded.
		def self.test_compile(src, options: Options.new)
			c = do_compile_file(src, File::NULL, options: options)
			#p c.success?, c.stdin, c.stdout, c.stderr
			c.success?
		end
		
		# Peform a test compile.
		#
		# @param (see do_compile_string)
		# @return [true,false] true if the compilation succeeded.
		def self.test_compile_string(src, options: Options.new)
			c = do_compile_string(src, File::NULL, options: options)
			#p c.success?, c.stdin, c.stdout, c.stderr
			c.success?
		end
		
		# Check to see if a macro is defined.
		#
		# @param name [String] macro identifier.
		# @return [true,false] true if the macro is defined.
		def self.test_macro(name)
			test_compile_string <<EOF
#ifndef #{name}
#error "#{name}Not Defined"
#endif
EOF
		end
	end
	
	R::Tool.load_dir(Pathname.new(__FILE__).realpath.dirname+"c/compiler/")
	
	tdir = Pathname.new(__FILE__).realpath.dirname + "c/test/"
	
	@compilers.keep_if do |n, c|
		c.available? or next false
		
		r = (
				c.test_compile(tdir+'basic.c') and
				not c.test_compile(tdir+'undefined.c') and
				c.test_macro '__LINE__'
			)
		
		r or $stderr.puts "Ignoring compiler #{n} because it failed the tests."
		
		r
	end
	
	D[:l_c_compiler].map! {|c| c.to_sym}
	
	@prefered_compiler = D[:l_c_compiler].find {|c| @compilers.has_key? c}
	
	# Return a compiler object.
	#
	# @param name [Symbol,nil,Object] The name of the compiler.
	# @return [Compiler] The compiler identified by +name+ or nil.  If a
	#                    non-symbol non-nil object is passed by in name it is
	#                    returned without ensuring it is a compiler.
	def self.compiler(name=nil)
		name ||= @prefered_compiler
		
		if name.is_a? Symbol
			@compilers[name]
		else
			name
		end
	end
	
		# Compile source files.
		#
		# @param src     [Set<Pathname,String>,Array<Pathname,String>,Pathname,String]
		#                The source files to compile and generated headers.
		# @param options [Options] An options object.
		# @return [Set<Pathname>] The resulting object files.
	def self.compile(src, compiler: nil, options: nil)
		src = R::Tool.make_set_paths src
		options ||= Options.new
		
		headers = Set.new
		src.keep_if do |s|
			if s.extname.match /[H]/i
			   headers << s
			   false
			else
				true
			end
		end
		
		compiler = compiler compiler
	
		src.map! do |s|
			out = R::Env.out_dir + 'l/c/objects/' + (Pathname.new(s).expand_path.to_s[1..-1] + '.o')
			
			TargetCSource.new(s, headers, options)
			::C.generator(s, compiler.compile_command(s, out), out, desc:"Compiling")
		end
		src.flatten!
		src
	end
	
	# A C source file.
	class TargetCSource < R::Target
		#def self.initialize
		#	@@inited and return
		#	
		#	
		#	
		#	@@inited = true
		#end
	
		def initialize(f, input = [], options = Options.new)
			#TargetC.initialize
			
			@f = Pathname.new(f).expand_path
			@opt = options
			@input = input
			
			register
		end
		
		def incs_from_cpp
			c = ::R::Command.new [
				::C.find_command('cpp'),
				#'-H',
				*@opt.include_dirs.map{|i| "-I#{i}"},
				@f
			]
			c.run
			
			#pp 'ERRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR'
			#puts c.stderr
			
			d = c.stdout.lines.map do |l|
				l.match(/^# [0-9]+ "(.|[^<].*[^>])"/) do |md|
					Pathname.new(md[1]).expand_path
				end
			end.select do |l|
				l
			end.uniq
			
			d.delete @f
			
			d
		end
		
		def input
			@incs and return @incs
			
			@input.map do |f|
				Pathname.new(f).expand_path
			end.map do |f|
				[f, R.get_target(f)]
			end.each do |f, i| 
				i.build
			end
			
			#puts "#@f depends on:"
			#pp incs_from_cpp
			
			@incs = incs_from_cpp
		end
		
		def output
			Set[@f]
		end
		
		def build
			build_dependancies
		end
	end
	
	# Compile and link an executable.
	#
	# @param src      [Set<Pathname,String>,Array<Pathname,String>,Pathname,String]
	#                 The source files to compile and generated headers.
	# @param lib      [Set<String>,Array<String>,String] Libraries to link with.
	# @param name     [Pathname,String] The basename of the output file.
	# @param options  [Options] An options object for the compiler.
	# @param loptions [L::LD::Options] An options object for the linker.
	# @return [Pathname] The resulting executable.
	def self.program(src, lib, name, 
	                 compiler: @prefered_compiler,
	                 options: nil,
	                 loptions: nil
	                )
		obj = compile(src, compiler: compiler, options: options)
		L::LD.link(obj, lib, name, format: :exe, linker: compiler.linker, options: loptions)
	end
end
