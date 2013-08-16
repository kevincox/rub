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

module L::LD
	LinkerLD = Linker.clone
	module LinkerLD
		def self.name
			:ld
		end
		
		def self.available?
			!!find
		end
		
		# Find the linker command.
		# @return [Pathname,nil] The command.
		def self.find
			C.find_command 'ld'
		end
		
		def self.link_command(files, libs, out, format: :exe, options: Options)
			files = R::Tool.make_set_paths files
			libs  = R::Tool.make_set libs
			out = C.path out
		
			c = [find, "-o#{out}"]
			
			c << options.args
			
			c << case format
				when :exe
					[]
				when :shared
					['-shared']
				else
					raise "Unknown/unsupported output #{format}."
			end
			
			c << case options.optimize
				when :none
					'-O0'
				when :some
					'-O0'
				when :full
					'-O1'
				when :max
					'-O9'
				else
					raise "Invalid optimization level #{options.optimize}."
			end
			
			c << if options.static
				'-static'
			else
				[]
			end
			
			c << options.library_dirs.map{|d| "-L#{d}"}
			
			c << libs.map{|l| "-l#{l}" }
			c << files.to_a
			
			c.flatten
		end
		
		#def self.find_lib(name, options: Options.new)
		#	options = options.deep_clone
		#	options.optimize = :none
		#	options.args << '-t'
		#	
		#	
		#	if options.static # The default way is best for static linking.
		#		return Linker.find_lib(name, options: options)
		#	end
		#	
		#	pp c = do_link([], [name], File::NULL, options: options)
		#	
		#	c.success? or return nil
		#	
		#	c.stdout.match(Regexp.new"^-l#{name} \\((.*)\\)$") do |m|
		#		m[1]
		#	end
		#end
	end
	L::LD.linkers[:ld] = LinkerLD
	
	D.append(:l_ld_linker, :ld)
end
