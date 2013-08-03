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

require 'rub/target'
require 'rub/system'

module R
	class TargetGenerator < TargetSmart
		attr_accessor :action
	
		def initialize
			super
			
			@action = 'Building'
			
			@cmd = []
		end
		
		def add_cmd(cmd)
			cmd = cmd.dup
			cmd[0] = C.find_command(cmd[0])
			@input << cmd[0]
			@cmd << cmd
			
			cmd
		end
		def add_cmds(cmds)
			cmds.map{|c| add_cmd c}
		end
		
		def build_self
			if clean?
				#p "#{self.inspect}: Already clean, not rebuilding."
				return
			end
			
			R::run(['mkdir', '-pv', *@output.map{|o| o.dirname}], "Preparing output directories", importance: :low)
			@cmd.all?{|c| R::run(c, "#@action #{@output.to_a.join", "}")} or exit 1
			
			clean
		end
	end
end
