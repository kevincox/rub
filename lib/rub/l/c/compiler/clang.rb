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

L::C::CompilerClang = L::C::Compiler.clone

# The Clang Compiler
module L::C::CompilerClang
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
	@@warn_flags = {
		true =>['-Wall'],
		false=>['-w'],
		:most=>['-Wall', '-Wextra'],
		:all =>['-Wall', '-Wextra'],
	}
	
	def self.generate_flags(opt)
		f = []
		
		f << '-emit-llvm' if opt.linktime_optimization
		
		f << '-g' if opt.debug
		
		f << @@warn_flags[opt.warn]
		f << '-Werror' if opt.warn_fatal
		
		f << @@o_flags[opt.optimize    ]
		f << @@o_flags[opt.optimize_for]
		
		f << opt.flags
		
		f << '-fPIC' if opt.pic
		
		f << opt.include_dirs.map do |d|
			"-I#{d}"
		end
		f << opt.define.map do |k, v|
			if v
				# -Dk if v is true else -Dk=v.
				"-D#{k}#{v.equal?(true)?"":"=#{v}"}"
			else
				"-U#{k}"
			end
		end
		
		f.flatten!
		f.compact!
	end
	
	def self.compile_command(opt, src, obj)
		[find, '-c', *generate_flags(opt), "-o#{obj}", *src]
	end
	
	def self.do_compile_string(opt, str, obj)
		c = R::Command.new [find, '-c', '-xc', *generate_flags(opt), '-o', obj, '-']
		c.stdin = str
		c.run
		c
	end
end
L::C.compilers[:clang] = L::C::CompilerClang
D.append(:c_compiler, :clang)
