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

# C Library
module L::C
	# @!scope class
	# All available compilers.
	# @return [Hash{Symbol=>Compiler}]
	cattr_reader   :compilers
	
	@compilers = {}

	# Compiler options.
	class Options
		# Compiler
		#
		# The compiler to use.
		#
		# @return (see compiler)
		# @see compiler
		cattr_accessor :compiler
		
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
		# A list of libraries to link.
		#
		# @return [Array<String,Pathname>]
		cattr_reader :libs
		
		# @!scope class
		# A list of macros to define.  nil can be used to undefine a macro.
		#
		# @return [Hash{String=>String,true,nil}]
		cattr_reader :define
		
		@debug = @profile = !!D[:debug]
		@optimize = @debug ? :none : :full
		
		@include_dirs = []
		@libs         = []
		@define = {
			@debug ? 'DEBUG' : 'NDEBUG' => true,
		}
		
		# Compiler
		#
		# The compiler to use.
		#
		# @return (see compiler)
		# @see compiler
		attr_accessor :compiler
		
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
	
		# @!scope class
		# A list of libraries to link.
		#
		# @return (see include_dirs)
		# @see include_dirs
		attr_reader :libs
		
		# Macro definitions.
		#
		# Override the global definitions list..
		#
		# @return (see define)
		# @see define
		attr_accessor :define
		
		def initialize(template = Options)
			@compiler     = template.compiler
			@optimize     = template.optimize
			@optimize_for = template.optimize_for
			
			@debug   = template.debug
			@profile = template.profile
			
			@include_dirs = template.include_dirs.dup
			@libs         = template.libs.dup
			@define       = template.define.dup
		end
		
		def self.dup
			new
		end
		def dup
			Options.new self
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
		def self.compile_command(src, obj, options: Options)
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
		# @param str     [Set<Pathname,String>,Array<Pathname,String>,Pathname,String]
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
		
		def self.include_directories(options)
			@include_directories and return @include_directories.dup
			
			cmd = [C.find_command('cpp'), '-v', '-o', File::NULL, File::NULL]
			c = R::Command.new cmd
			c.run
			
			l = c.stderr.lines.map &:chomp
			
			#qb = l.find_index('#include "..." search starts here:') + 1
			sb = l.find_index('#include <...> search starts here:') + 1
			se = l.find_index 'End of search list.'
			
			@include_directories = l[sb...se].map{|d| Pathname.new d[1..-1] }
			
			@include_directories.dup
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
	
	Options.compiler = @compilers[ D[:l_c_compiler].find {|c| @compilers.has_key? c} ]
	
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
	def self.compile(src, options: Options)
		src = R::Tool.make_set_paths src
		
		headers = Set.new
		src.keep_if do |s|
			if s.extname.match /[H]/i
			   headers << s
			   false
			else
				true
			end
		end
	
		src.map! do |s|
			out = R::Env.out_dir + 'l/c/' + C.unique_segment(options) + "#{s.basename}.o"
			
			R.find_target(s) or TargetCSource.new(s, headers, options)
			::C.generator(s, options.compiler.compile_command(s, out, options: options), out, desc:"Compiling")
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
	
		def initialize(f, input = [], options = Options)
			#TargetC.initialize
			
			@f = C.path(f)
			@opt = options
			@input = input
			
			register
		end
		
		def included_files(set=Set.new, options=Options)
			set.include?(@f) and return
		
			set << @f
			@incs ||= @f.readlines.map do |l|
				l =~ /\s*#\s*include\s*("(.*)"|<(.*)>)/ or next
				if $3 and !D[:l_c_system_headers]
					next
				end
				
				p  = Pathname.new( $2 || $3 )
				ip = @opt.compiler.include_directories(@opt)
				
				if $2
					ip << @f.dirname
				end
				
				h = nil
				ip.each do |d|
					hg = d.join(p)
					
					if hg.exist?
						h = hg
						break
					end
				end
				
				h # Ignoring missing headers for now.
			end.compact
			
			@incs.each do |h|
				icd = R::find_target(h) || TargetCSource.new(h, @input, @opt)
				
				if icd.respond_to? :included_files
					icd.included_files set, options
				else
					set << h
				end
			end
		end
		
		def input
			@input + included_files
		end
		
		def output
			Set[@f]
		end
		
		def build
			@depsbuilt and return
		
			@depsbuilt = true
			build_dependancies
		end
	end
	
	def self.to_c_identifier(s)
		s.delete('`!@#$%^&*()+=[]{};"\'<>?')
		 .gsub(/[\~\-\\\|\:\,\.\/]/, '_')
		 .gsub(/^[0-9]/, '_\0')
	end
	
	class TargetGeneratedHeader < R::TargetSmart
		def initialize(name, h, c, values, options: Options)
			super()
			
			@n = name
			@h = h
			@c = c
			
			@val = values
			
			output << @h << @c
		end
		
		def hash_input
			Digest::SHA1.digest(@val.inspect)
		end
		
		def hash_output(t)
			Digest::SHA1.digest(t.readlines.drop(2).join('\n'))
		end
		
		def build_self
			@h.dirname.mkpath
			@c.dirname.mkpath
			
			h = @h.open('w')
			c = @c.open('w')
			
			notice = <<"EOS"
/* THIS FILE IS AUTOMATICALLY GENERATED - DO NOT EDIT! */
/* This file was generated by Rub on #{DateTime.now.iso8601} */

EOS
			h.print notice
			c.print notice
			
			hname = L::C.to_c_identifier(@h.basename.to_s).upcase
			h.puts "#ifndef RUB_L_C_GENERATE_HEADER___#{hname}"
			h.puts "#define RUB_L_C_GENERATE_HEADER___#{hname}"
			h.puts ''
			
			c.puts %|#include "#{@n}.h"|
			c.puts ''
			
			@val.each do |k, v|
				type, v = if v.is_a?(Array)
					[v[0], v[1]]
				elsif v.is_a? Numeric
					['int', v.to_s]
				elsif v.equal?(true) || v.equal?(false)
					['short unsigned int', v ? 1 : 0]
				elsif v.respond_to? :to_s
					['const char *', v.to_s.inspect] # @TODO: make this quote for C rather then ruby.
				end
			
				h.puts "extern #{type} #{k};"
				c.puts "#{type} #{k} = #{v};"
			end
			
			h.puts ''
			h.puts "#endif /* RUB_L_C_GENERATE_HEADER___#{hname} */"
			
			h.close
			c.close
			
			bs = R::BuildStep.new
			bs.desc = "Generating #{@h} and #{@c}"
			bs.print
		end
	end
	
	# Generate a header
	#
	# Generates a header with information in it.
	def self.generate_header(name, vals, options: Options)
		h = C.unique_path("#{name}.h", vals)
		c = C.unique_path("#{name}.c", vals)
		
		t = TargetGeneratedHeader.new(name, h, c, vals)
		t.register
		
		options.include_dirs << h.dirname
		
		t.output
	end
	
	# Compile and link an executable.
	#
	# @param src      [Set<Pathname,String>,Array<Pathname,String>,Pathname,String]
	#                 The source files to compile and generated headers.
	# @param name     [Pathname,String] The basename of the output file.
	# @param options  [Options] An options object for the compiler.
	# @param loptions [L::LD::Options] An options object for the linker.
	# @return [Pathname] The resulting executable.
	def self.program(src, name,
	                 options: Options,
	                 loptions: L::LD::Options
	                )
		compiler = compiler compiler
		
		obj = compile(src, options: options)
		L::LD.link(obj, options.libs, name, format: :exe, linker: options.compiler.linker, options: loptions)
	end
end
