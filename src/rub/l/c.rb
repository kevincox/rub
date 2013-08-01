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

module L::C
	cattr_accessor :compiler
	cattr_reader   :compilers
	
	@compilers = {}
	@prefered_compiler = nil

	OPTIMIZE_NONE = :none
	OPTIMIZE_SOME = :some
	OPTIMIZE_FULL = :full
	OPTIMIZE_MAX  = :max
	
	OPTIMIZE_FOR_SIZE  = :size
	OPTIMIZE_FOR_SPEED = :speed

	class Options
		cattr_accessor :optimize, :optimize_for
		cattr_accessor :debug, :profile
	
		cattr_reader :include_dirs, :define
		
		@@debug = @@profile = (not not D[:debug])
		@@optimize = @@debug ? :none : :full
		
		@@include_dirs = []
		@@define = {
			@@debug ? 'DEBUG' : 'NDEBUG' => true,
		}
		
		attr_accessor :optimize, :optimize_for
		attr_accessor :debug, :profile
	
		attr_reader :include_dirs, :define
		
		def initialize
			@optimize     = @@optimize
			@optimize_for = @@optimize_for
			
			@debug   = @@debug
			@profile = @@profile
			
			@include_dirs = @@include_dirs.dup
			@define       = @@define.dup
		end
	end
	
	module Compiler
		def self.name
			:default
		end
		
		def self.available?
			false
		end
		
		def self.linker
			nil
		end
		
		def self.compile_command(src, obj, options: Options.new)
			raise "Not implemented!"
		end
		
		def self.do_compile_file(f, obj, options: Options.new)
			compile_command(f, obj)
			c = R::Command.new(compile_command(f, obj, options: options))
			c.run
			c
		end
		
		def self.do_compile_string(str, obj, options: Options.new)
			f = Tempfile.new(['rub.l.c.testcompile', '.c'])
			f.write(str)
			f.close
			c = do_compile_file(f.path, obj, options: options)
			f.unlink
			c
		end
		
		def self.test_compile(src, options: Options.new)
			c = do_compile_file(src, File::NULL, options: options)
			#p c.success?, c.stdin, c.stdout, c.stderr
			c.success?
		end
		
		def self.test_compile_string(src, options: Options.new)
			c = do_compile_string(src, File::NULL, options: options)
			#p c.success?, c.stdin, c.stdout, c.stderr
			c.success?
		end
		
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
	
	def self.compiler(name=nil)
		name ||= @prefered_compiler
		
		if name.is_a? Symbol
			@compilers[name]
		else
			name
		end
	end
	
	def self.compile(src, compiler: @prefered_compiler, options: Options.new)
		src = R::Tool.make_array_paths src
		headers = []
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
		end.flatten!
	end
	
	class TargetCSource < ::R::Target
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
			[@f]
		end
	end
	
	def self.program(src, lib, name, 
	                 compiler: @prefered_compiler,
	                 options: Options.new,
	                 loptions: nil
	                )
		src = R::Tool.make_array_paths src
		lib = R::Tool.make_array lib
		compiler = compiler compiler
		
		obj = compile(src, compiler: compiler, options: options)
		
		L::LD.link(obj, lib, name, format: :exe, linker: compiler.linker, options: loptions)
	end
end
