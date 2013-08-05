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

require 'rub'

module R

	# A high level interface for executing commands.
	class Command
		# @!attribute [r] cmd
		#   @return [Array<String>] The command to run.
		attr_reader   :cmd
		
		# @!attribute [r] env
		#   
		#   Control the environment of the spawned process.  Values from this
		#   hash will be added to the processes environment.  If a value is
		#   nil the key will be removed from the processes environment.  These
		#   values are overlaid on the existing environment unless {#clearenv}
		#   is set.
		#   
		#   @return [Hash{String=>String,nil}] The environment variables.
		attr_reader   :env
	
		# @!attribute [rw] stdin
		#   @return [String] The string to use as input to the command.
		attr_accessor :stdin
		# @!attribute [r] stdout
		#   @return [String] The output produced by the command.
		# @!attribute [r] stderr
		#   @return [String] The error output produced by the command.
		attr_reader   :stdout, :stderr
		
		# @!attribute [r] status
		#
		#   Available after {#block} has returned.
		#
		#   @return [Process::Status,nil] The processes exit status.
		attr_reader   :status
		
		# @!attribute [rw] clearenv
		#   If set, the executed command will not inherit environment variables
		#   from Rub.  Only the values in {#env} will be present in the
		#   environment.
		#   
		#   Defaults to false.
		#   
		#   @return [true,false] If true don't inherit the environment.
		attr_accessor :clearenv
		# @!attribute [rw] mergeouts
		#   @return [true,false] If true merge {#stdout} into {#stderr}.
		attr_accessor :mergeouts
		
		# Create a new command to run.
		#
		# @param cmd [Array<String,#to_s>] The command that will be run.
		def initialize(cmd)
			@env = {}
			
			@clearenv = false
			@mergeouts = false
			
			@cmd = cmd.map{|a| a.to_s}
		end
		
		# Start the command.
		#
		# Executes the command.  The command will run in the background.  If you
		# want to wait for the command to complete call {#block}.
		#
		# @note Calling this command a second time before {#block} returns
		#       produces undefined behaviour.  A {Command} can be run multiple
		#       times but it must finish before being run again.
		def start
			@status = nil
		
			@stdinr,  @stdinw  = IO.pipe
			@stdoutr, @stdoutw = IO.pipe
			@stderrr, @stderrw = IO.pipe
			
			@stdin  = ""
			@stdout = ""
			@stderr = ""
			@status = nil
			
			args = [
				@env,
				*@cmd.map{|a| a.to_s},
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
		
		# Run the command and block until completion.
		#
		# Equivalent to calling {#start} then {#block}.
		#
		# @return [true,false] Whether the command completed successfully.
		def run
			start
			block
		end
		
		# Wait for a command to finish.
		#
		# Block until a currently running process finishes.  Behaviour is
		# undefined if the command is not currently running ({#start} has been
		# called since the last {#block}).
		#
		# After this call returns {#status} will be available.
		#
		# @return [true,false] Whether the command completed successfully.
		def block
			@stdout = @stdoutr.read
			@stderr = @stderrr.read
			
			#puts "Blocking on #{@pid} #{@cmd.join' '}"
			pid, @status = Process.wait2 @pid
			#puts "Done #{@cmd.join' '}"
			
			@stdoutr.close
			@stderrr.close
			
			success?
		end
		
		# Check if the command was successful
		#
		# @return [true,false] true if the command executed successfully
		#                      otherwise false.
		# @note If the command has not been executed or has not completed this
		#       returns false.
		def success?
			!!( @status and @status.exitstatus == 0 )
		end
	end
	
	# Run a command as part of the build.
	#
	# The command will be run and status will be printed.
	#
	# @param cmd  [Array<String,#to_s>] The command to execute.
	# @param desc [String] The verb describing what the command is doing.
	# @param importance [Symbol] The importance of this step.  Affects printing.
	# @return [true,false] true if the command was successful.
	def self.run(cmd, desc, importance: :med)
		cmd = cmd.dup
	
		bs = BuildStep.new
		bs.desc = desc
		bs.cmd  = cmd
		bs.importance = importance
		
		pp cmd[0]
		cpath = C.find_command cmd[0]
		if not cpath
			raise "Could not find #{cmd[0]}.  Please install it or add it to your path."
		end
		cmd[0] = cpath
		cmd.map!{|a| a.to_s}
		
		c = Command.new(cmd)
		c.mergeouts = true
		
		c.run
		
		bs.out    = c.stdout
		bs.status = c.status.exitstatus
		
		bs.print
		
		c.success?
	end
	
	# Manages reporting build progress.
	class BuildStep
		# The verb describing this step.
		# @return [String]
		attr_accessor :desc
		
		# The command to execute.
		# @return [Array<String>]
		attr_accessor :cmd
		
		# The command output.
		# @return [String]
		attr_accessor :out
		
		# The exit status of the command.
		# @return [Process::Status]
		attr_accessor :status
		
		# The command's importance.
		# @return [Symbol] :low, :medium or :high
		attr_reader :importance
		
		# Set the command's importance.
		# @param i [Symbol] :low, :medium or :high
		# @return [Symbol] +i+
		def importance=(i)
			@importance = i
			case i
				when :low
					@importancei = 1
				when :med
					@importancei = 2
				when :high
					@importancei = 3
			end
		end
		
		# Constructor
		#
		# @param cmd  [Array<String>] The command executed.
		# @param out  [String]        The output generated.
		# @param desc [String]        A verb describing the event.
		def initialize(cmd=[], out="", desc="", status=0)
			@cmd    = cmd
			@out    = out
			@desc   = desc
			@status = status
			
			importance = :high
		end
		
		# Format the command.
		#
		# Format's the command in the prettiest way possible.  Theoretically
		# this command could be pasted into a shell and execute the desired
		# command.
		#
		# @param cmd [Array<String>] The command.
		def format_cmd(cmd)
			cmd.map do |e|
				if /[~`!#$&*(){};'"]/ =~ e
					"'#{e.sub(/['"]/, '\\\1')}'"
				else
					e
				end
			end.join(' ')
		end
		
		# Print the result.
		def print
			@importancei < 2 and return
		
			puts "\e[#{status==0 ? '' : '31;'}1m#{@desc}\e[0m"
			puts format_cmd @cmd
			Kernel::print @out
		end
	end
end
