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

require 'pathname'

require 'rub/targetcommand'

module C
	def self.path(p)
		p = p.to_s
		
		p = case p[0]
			when '!'
				Pathname.new(p[1..-1])
			when '>'
				Rub::Env.out_dir + p[1..-1]
			when '<'
				Rub::Env.src_dir + p[1..-1]
			else
				Pathname.new(p)
		end
		
		p = p.expand_path
	end
	
	class Tag
		def initialize(t)
			@target = Rub::Target.new
			@target.out << t
			@target.register
		end
		
		def require(f)
			@target.in << C.path(f)
		end
	end
	
	def self.tag(t)
		p = Rub::Env.cmd_dir + t
		p = p.expand_path
		
		t = Rub.targets[p]
		
		if not t
			t = Tag.new(p)
		end
		
		t
	end
	
	def self.generator(src, cmd, out)
		t = Rub::TargetCommand.new
		
		src   .is_a?(Array) or src = [src]
		out   .is_a?(Array) or out = [out]
		cmd[0].is_a?(Array) or cmd = [cmd]
		
		t.in .concat(src)
		t.out.concat(out)
		t.add_cmds cmd
		
		t.register
		
		out
	end
	
	def self.find_command(cmd)
		exe = Rub.spersistant["C.find_command.#{cmd}"]
		
		exe and exe.executable? and return exe

		exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
		names = exts.map{|e| cmd+e}
		ENV['PATH'].split(File::PATH_SEPARATOR)
		           .map{|d|Pathname.new(d)}
		           .each do |d|
			names.each do |n|
				exe = d + n
				p exe
				
				exe.executable? and break
			end
			
			exe.executable? and break
		end
		
		Rub.spersistant["C.find_command.#{cmd}"] = exe
	end
end
