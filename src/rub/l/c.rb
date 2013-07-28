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

module L
	module C
		class << self
			attr_accessor :compiler
			attr_reader   :compilers
		end
		@compilers = {}
		@prefered_compiler = nil
	
		OPTIMIZE_NONE = :none
		OPTIMIZE_SOME = :some
		OPTIMIZE_FULL = :full
		OPTIMIZE_MAX  = :max
		
		OPTIMIZE_FOR_SIZE  = :size
		OPTIMIZE_FOR_SPEED = :speed
	
		class Options
			attr_accessor :optimize, :optimize_for
			attr_accessor :debug, :profile
		
			attr_reader :include_dirs, :define
			
			def initialize
				@debug = @profile = (not not D[:debug])
				@optimize = @debug ? :none : :full
				
				@include_dirs = []
				@define = {
					@debug ? 'DEBUG' : 'NDEBUG' => true,
				}
			end
		end
		
		class Compiler
			attr_reader :name
			attr_reader :options
			
			def initialize
				@name = :default
			
				@options = Options.new
			end
			
			def available?
				false
			end
			
			def compile_command(src, obj)
				raise "Not implemented!"
			end
			
			def do_compile_file(f, obj)
				c = R::Command.new(compile_command(f, obj))
				c.run
				c
			end
			
			def do_compile_string(str, obj)
				f = Tempfile.new(['rub.l.c.testcompile', '.c'])
				f.write(str)
				f.close
				c = do_compile_file(f.path, obj)
				f.unlink
				c
			end
			
			def test_compile(src)
				c = do_compile_file(src, File::NULL)
				#p c.success?, c.stdin, c.stdout, c.stderr
				c.success?
			end
			
			def test_compile_string(src)
				c = do_compile_string(src, File::NULL)
				#p c.success?, c.stdin, c.stdout, c.stderr
				c.success?
			end
			
			def test_macro(name)
				test_compile_string <<EOF
#ifndef #{name}
#error "#{name}Not Defined"
#endif
EOF
			end
		end
		
		cdir = Pathname.new(__FILE__).realpath.dirname + "c/compiler/"
		tdir = Pathname.new(__FILE__).realpath.dirname + "c/test/"
		cdir.children.each {|c| load c}
		
		@compilers.keep_if do |n, c|
			c = c.new
			
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
		
		def self.new_compiler(name=@prefered_compiler)
			klass = @compilers[name]
			return klass ? klass.new : nil
		end
		
		@compiler = new_compiler
		
		def self.compile(src, compiler: @compiler)
			src = R::Tool.make_array src
		
			src.map! do |s|
				out = R::Env.out_dir + 'l/c/objects/' + (Pathname.new(s).expand_path.to_s[1..-1] + '.o')
				
				::C.generator(s, compiler.compile_command(s, out), out, desc:"Compiling")
			end.flatten!
		end
	end
end
