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
	# All available compilers.
	# @return [Hash{Symbol=>Compiler}]
	cattr_accessor :compilers
	@compilers = {}
	
	# Compiler
	#
	# The compiler to use.
	#
	# @return (see compiler)
	# @see compiler
	cattr_reader :compiler
	def self.compiler=(name)
		@compiler = get_compiler name
	end
	
	# Default debug symbols setting.
	#
	# This determines if the compiler should produce debugging symbols.
	#
	# @return [true,false]
	cattr_accessor :debug
	@debug = !!D[:debug]
	
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
	@optimize = @debug ? :none : :full
	
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
	
	# Default profile symbols setting.
	#
	# This determines if the compiler should produce code suitable for
	# profiling.
	#
	# @return [true,false]
	cattr_accessor :profile
	@profile = @debug
	
	# A list of directories to search for header files.
	#
	# These paths are searched in order.
	#
	# @return [Array<Pathname>]
	cattr_accessor :include_dirs
	@include_dirs = R::Tool::PathArray.new
	
	# A list of libraries to link.
	#
	# @return [Array<String,Pathname>]
	cattr_accessor :libs
	@libs = L::LD::LibraryArray.new
	
	# A list of macros to define.  `nil` can be used to undefine a macro.
	#
	# @return [Hash{String=>String,true,nil}]
	cattr_accessor :define
	@define = {
		@debug ? 'DEBUG' : 'NDEBUG' => true,
	}
	
	# A list of arguments to pass to the compiler.
	# 
	# WARNING: This makes your build description compiler-specific.  Only use
	# this if the provided options are not sufficent.
	cattr_accessor :flags
	@flags = R::Tool.make_array(D[:c_flags]) || []
	
	# What warnings to emit.
	#
	# Valid values:
	# - nil Compiler default.
	# - true Display basic warnings.
	# - false Disable warnings.
	# - :most Display most warnings.
	# - :all Display all available warnings.
	cattr_accessor :warn
	
	# Die on warning.
	#
	# Die on any warning, if supported by the compiler.
	cattr_accessor :warn_fatal
	@warn_fatal = false
	
	# Generate position independent code.
	cattr_accessor :pic
	@pic = false
	
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
		# @param src [Set<Pathname>] The source files to link and generated headers.
		# @param obj [Pathname] The path of the output file.
		# @param opt [Options] An options object.
		# @return [Pathname] The output file.
		def self.compile_command(opt, src, obj)
			raise "Not implemented!"
		end
		
		# Compile a file.
		#
		# @param (see compile_command)
		# @return [R::Command] the process that compiled the file.
		def self.do_compile_file(opt, f, obj)
			c = R::Command.new(compile_command(opt, f, obj))
			c.run
			c
		end
		
		# Compile a string.
		#
		# @param str [String] A string containing the complete source to compile.
		# @param obj [Pathname] The path of the output file.
		# @param opt [Options] An options object.
		# @return [R::Command] the process that compiled the string.
		def self.do_compile_string(opt, str, obj)
			f = Tempfile.new(['rub.l.c.testcompile', '.c'])
			f.write(str)
			f.close
			c = do_compile_file(opt, f.path, obj)
			f.unlink
			c
		end
		
		# Peform a test compile.
		#
		# @param (see do_compile_file)
		# @return [true,false] true if the compilation succeeded.
		def self.test_compile(opt, src)
			c = do_compile_file(opt, src, File::NULL)
			#p c.success?, c.stdin, c.stdout, c.stderr
			c.success?
		end
		
		# Peform a test compile.
		#
		# @param (see do_compile_string)
		# @return [true,false] true if the compilation succeeded.
		def self.test_compile_string(opt, src)
			c = do_compile_string(opt, src, File::NULL)
			#p c.success?, c.stdin, c.stdout, c.stderr
			c.success?
		end
		
		# Check to see if a macro is defined.
		#
		# @param name [String] macro identifier.
		# @return [true,false] true if the macro is defined.
		def self.test_macro(opt, name)
			test_compile_string opt, <<-EOF.gsub(/^\s+/, '')
				#ifndef #{name}
				#error "#{name}Not Defined"
				#endif
			EOF
		end
		
		def self.include_directories(opt)
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
	
	def self.get_compiler(name)
		if name.is_a? Symbol
			compilers[name]
		else
			name
		end
	end
	
	R::Tool.load_dir(Pathname.new(__FILE__).realpath.dirname+"c/compiler/")
	
	tdir = Pathname.new(__FILE__).realpath.dirname + "c/test/"
	
	@compilers.keep_if do |n, c|
		c.available? or next false
		
		r = (
				c.test_compile(self, tdir+'basic.c') and
				not c.test_compile(self, tdir+'undefined.c') and
				c.test_macro(self, '__LINE__')
			)
		
		r or $stderr.puts "Ignoring compiler #{n} because it failed the tests."
		
		r
	end
	
	D[:c_compiler].map! {|c| c.to_sym}
	@compiler = compilers[ D[:c_compiler].find{|c| compilers.has_key? c} ]
	
	# Compile source files.
	#
	# @param src     [Set<Pathname,String>,Array<Pathname,String>,Pathname,String]
	#                The source files to compile and generated headers.
	# @param opt [Options] An options object.
	# @return [Set<Pathname>] The resulting object files.
	def self.compile(src)
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
			out = R::Env.out_dir + 'l/c/' + C.unique_segment(self) + "#{s.basename}.o"
			
			R.find_target(s) or TargetCSource.new(self, s, headers)
			::C.generator(s, compiler.compile_command(self, s, out), out, desc:"Compiling")
		end
		src.flatten!
		src
	end
	
	# A C source file.
	class TargetCSource < R::Target
		def initialize(opt, f, input = Set.new)
			#TargetC.initialize
			
			@f = C.path(f)
			@opt = opt
			@input = input
			
			register
		end
		
		def included_files(opt, set=Set.new)
			set.include?(@f) and return set
			
			set << @f
			@incs ||= @f.readlines.map do |l|
				l =~ /\s*#\s*include\s*("(.*)"|<(.*)>)/ or next
				if $3 and !D[:c_system_headers]
					next
				end
				
				p  = Pathname.new( $2 || $3 )
				ip = opt.compiler.include_directories(opt)
				
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
				icd = R::find_target(h) || TargetCSource.new(opt, h)
				
				if icd.respond_to? :included_files
					icd.included_files opt, set
				else
					set << h
				end
			end
			
			return set
		end
		
		def input
			@input + included_files(@opt)
		end
		
		def output
			Set[@f]
		end
		
		def hash_output(f)
			C.hash(input.map do |f| # Include files are effectively us.
				t = R.find_target f
				
				if t.respond_to? :hash_only_self
					t.hash_only_self
				else
					t.hash_output t
				end
			end.join('\0'))
		end
		
		def hash_only_self
			@hashcache ||= C.hash_file @f
		end
		
		def invalidate
			@hashcache = nil
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
		def initialize(opt, name, h, c, values)
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
	def self.generate_header(name, vals)
		h = C.unique_path("#{name}.h", vals)
		c = C.unique_path("#{name}.c", vals)
		
		t = TargetGeneratedHeader.new(self, name, h, c, vals)
		t.register
		
		include_dirs << h.dirname
		
		t.output
	end
	
	# Compile and link an executable.
	#
	# @param src      [Set<Pathname,String>,Array<Pathname,String>,Pathname,String]
	#                 The source files to compile and generated headers.
	# @param name     [Pathname,String] The basename of the output file.
	# @return [Pathname] The resulting executable.
	def self.program(src, name)
		obj = compile(src)
		linker = L::LD.clone
		
		linker.set_linker compiler.linker
		linker.link(obj, libs, name, format: :exe)
	end
	
	# Compile and link a shared library.
	#
	# @param src      [Set<Pathname,String>,Array<Pathname,String>,Pathname,String]
	#                 The source files to compile and generated headers.
	# @param name     [Pathname,String] The basename of the output file.
	# @param version  The version of the library.  The major version will be
	#                 used for the soname.
	# @return [Pathname] The resulting executable.
	def self.shared(src, name, version=nil)
		scplr = L::C.clone
		scplr.pic = true
		obj = scplr.compile(src)
		
		linker = L::LD.clone
		linker.set_linker compiler.linker
		linker.link(obj, libs, name, format: :shared, ver: version)
	end
	
	def self.initialize_copy(s)
		super
		
		self.include_dirs = s.include_dirs.dup
		self.libs = s.libs.dup
		self.define = s.define.dup
	end
end
