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

module L
	module LD
		cattr_reader   :linkers
		
		@linkers = {}
		@prefered_linker = nil
	
		OPTIMIZE_NONE = :none
		OPTIMIZE_SOME = :some
		OPTIMIZE_FULL = :full
		OPTIMIZE_MAX  = :max
	
		class Options
			cattr_accessor :optimize
			cattr_reader   :library_dirs
			cattr_accessor :static
			cattr_accessor :args
			
			@@optimize = D[:debug] ? :none : :full
			@@library_dirs = []
			@@static = false
			@@args = []
			
			attr_accessor  :optimize
			attr_reader    :library_dirs
			attr_accessor  :static
			attr_accessor  :args
			
			def initialize
				@optimize     = @@optimize
				@static       = @@static
				@library_dirs = @@library_dirs.dup
				@args         = @@args.dup
			end
		end
		
		module Linker
			def self.available?
				false
			end
			
			def self.link_command(files, libs, out, format: :exe, options: Options.new)
				raise "Not implemented!"
			end
			
			def self.do_link(files, libs, out, format: :exe, options: Options.new)
				c = R::Command.new(link_command(files, libs, out, format: :exe, options: options))
				c.run
				c
			end
			
			def self.test_link(files, libs, format: :exe, options: Options.new)
				c = do_link(files, libs, File::NULL, format: :exe, options: options)
				#p c.success?, c.stdin, c.stdout, c.stderr
				c.success?
			end
			
			@@name_map = {
				exe:    '%s',
				shared: 'lib%s.so',
				static: 'lib%s.a',
			}
			
			def self.full_name(base, type)
				@@name_map[type] % base
			end
			
			def self.find_lib(name, options: Options.new)
				whereis = ::C::find_command('whereis') or return nil
				
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
		
		def self.linker(name=nil)
			name ||= @prefered_linker
		
			if name.is_a? Symbol
				@linkers[name]
			else
				name
			end
		end
		
		def self.link(src, libs, name, format: :exe, linker: @prefered_linker, options: Options.new)
			src  = R::Tool.make_array_paths src
			libs = R::Tool.make_array libs
			
			linker = linker linker
			
			libfs = libs.map {|l| linker.find_lib l or raise "Can't find library #{l}."}
			
			out = linker.full_name name, format
			out = R::Env.out_dir + 'l/ld/' + out
			
			::C::generator(src+libfs, linker.link_command(src, libs, out, format: format, options: options), out)
			
			out
		end
	end
end
