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

module L::C
	CompilerClang = Compiler.clone
	module CompilerClang
		
		def self.name
			:clang
		end
		
		def self.available?
			!!find
		end
		
		def self.find
			@exe and return @exe
		
			@exe = ::C.find_command 'clang'
		end
		
		def self.linker
			:clang
		end
		
		@@o_flags = {
			:none=>'-O0',
			:some=>'-O1',
			:full=>'-O3',
			:max =>'-O4',
		}
		@@of_flags = {
			nil=>[],
			:speed=>[],
			:size=>'-Os',
		}
		
		def self.generate_flags(options)
			f = []
			
			#f << '-emit-llvm'
			
			f << (@@o_flags[options.optimize    ] || [])
			f << (@@o_flags[options.optimize_for] || [])
			
			f << options.include_dirs.map do |d|
				"-I#{d}"
			end
			f << options.define.map do |k, v|
				if v
					# -Dk if v is true else -Dk=v.
					"-D#{k}#{v.equal?(true)?"":"=#{v}"}"
				else
					"-U#{k}"
				end
			end
			
			f.flatten!
		end
		
		def self.compile_command(src, obj, options: Options)
			[find, '-c', *generate_flags(options), "-o#{obj}", *src]
		end
		
		def self.do_compile_string(str, obj, options: Options.new)
			c = R::Command.new [find, '-c', '-xc', *generate_flags(options), '-o', obj, '-']
			c.stdin = str
			c.run
			c
		end
	end
	L::C.compilers[:clang] = CompilerClang
	
	D.append(:l_c_compiler, :clang)
end
