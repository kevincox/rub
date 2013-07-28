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

module R
	class Command
		attr_reader   :env
	
		attr_accessor :stdin
		attr_reader   :stdout, :stderr
		
		attr_reader   :status
		
		attr_accessor :clearenv
		attr_accessor :mergeouts
	
		def initialize(cmd)
			@env = {}
			
			@stdin  = ""
			@stdout = ""
			@stderr = ""
			
			@opt = {}
			
			@cmd = cmd.map{|a| a.to_s}
		end
		
		def start
			@status = nil
		
			@stdinr,  @stdinw  = IO.pipe
			@stdoutr, @stdoutw = IO.pipe
			@stderrr, @stderrw = IO.pipe
		
			args = [
				@env,
				*@cmd,
				:unsetenv_others=>@clearenv,
				:in =>@stdinr,
				:out=>@stdoutw,
				:err=>(@mergeouts?@stdoutw:@stderrw),
			]
			
			#p "args: #{args}"
			@pid = spawn(*args)
			
			@stdinr.close
			
			@stdinw.write @stdin
			
			@stdinw.close
			@stdoutw.close
			@stderrw.close
			
			@pid
		end
		
		def run
			start
			block
		end
		
		def block
			pid, @status = Process.wait2 @pid
			
			@stdout = @stdoutr.read
			@stderr = @stderrr.read
			
			@stdoutr.close
			@stderrr.close
			
			success?
		end
		
		def success?
			not not ( @status and @status.exitstatus == 0 )
		end
	end
	
	def self.run(cmd, desc)
		cmd = cmd.map{|a| a.to_s}
	
		bs = BuildStep.new
		bs.desc = desc
		bs.cmd  = cmd
		
		c = Command.new(cmd)
		c.mergeouts = true
		
		c.run
		
		bs.out    = c.stdout
		bs.status = c.status.exitstatus
		
		bs.print
		
		c.success?
	end
	
	class BuildStep
		attr_accessor :desc
		attr_accessor :cmd
		attr_accessor :out
		attr_accessor :status
		
		def initialize(cmd=[], out="", desc="", status=0)
			@cmd    = cmd
			@out    = out
			@desc   = desc
			@status = status
		end
		
		def format_cmd(cmd)
			cmd.map do |e|
				if /[~`!#$&*(){};'"]/ =~ e
					"'#{e.sub(/['"]/, '\\\1')}'"
				else
					e
				end
			end.join(' ')
		end
		
		def print
			puts "\e[1m#@desc\e[0m"
			puts format_cmd @cmd
			Kernel::print @out
		end
	end
end
