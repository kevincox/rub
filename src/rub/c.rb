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

require 'rub/tool'
require 'rub/targetgenerator'

module C
	# Expand a path.
	#
	# Not documented because it may be removed.
	#
	# @deprecated Use +Pathname#new+ instead.
	def self.path(p)
		#raise "crash me" if caller.length > 500
		p = p.to_s
		
		p = case p[0]
			when '!'
				Pathname.new(p[1..-1])
			when '>'
				R::Env.out_dir + p[1..-1]
			when '<'
				R::Env.src_dir + p[1..-1]
			else
				Pathname.new(p)
		end
		
		p = p.expand_path
	end
	
	# Tag Target
	#
	# This is the target used for tags.
	class TargetTag < R::Target
		attr_reader :output, :input
		
		def initialize(t)
			@output = [t]
			@input  = []
		end
		
		def require(f)
			f = R::Tool.make_array f
			
			input.concat f.map!{|e| C.path(e)}
		end
	end
	private_constant :TargetTag
	
	# Tag class
	#
	# Manages a tag.  This should not be created buy the user but retrieved from
	# {C.tag}.
	class Tag
		def initialize(t)
			@target = TargetTag.new(t)
			@target.register
		end
		
		def require(f)
			@target.require f
		end
	end
	
	# Get a tag.
	#
	# If the tag already exists it returns the existing {Tag} object otherwise
	# it creates and returns a new {Tag} instance.
	#
	# @param t [String] The tag name.  It is recommended that it starts with a
	#                   '=' although this is not enforced.
	# @return [Tag]     The tag object.
	def self.tag(t)
		p = R::Env.cmd_dir + t
		p = p.expand_path
		
		R.targets[p] || Tag.new(p)
	end
	
	##### Create default tags.
	::C.tag('=all')
	::C.tag('=install')
	::C.tag('=help')
	::C.tag('=none')
	
	# Add a generator to the build
	#
	# This function provides a simple api for creating {R::TargetGenerator}
	# targets.  It creates a target that simply runs one or more commands to
	# transform it's inputs into outputs.  This interface handles all build
	# caching and parallelization.
	#
	# @param src [Array<Pathname,String>,Pathname,String]
	#            The source file or list of source files.
	# @param cmd [Array<Array<Pathname,String>>,Array<Pathname,String>]
	#            The command or list of commands to run.  Commands will run in
	#            order.
	# @param out [Array<Pathname,String>,Pathname,String]
	#            The output files of the command.
	# @param desc The verb for this step in the process. (See
	#             {R::TargetGenerator#action})
	# @return [Array<Pathname>] The output files.  This will represent the same
	#                           values passed in to the +out+ parameter but it
	#                           will be a new Array and all the values will be
	#                           Pathnames.
	def self.generator(src, cmd, out, desc: nil)
		t = R::TargetGenerator.new
		
		desc and t.action = desc
		
		src = R::Tool.make_array(src)
		out = R::Tool.make_array(out)
		cmd[0].is_a?(Array) or cmd = [cmd]
		
		t.input .concat(src)
		t.output.concat(out)
		t.add_cmds cmd
		
		t.register
		
		out
	end
	
	# Find an executable on the system.
	#
	# This searches the system for execrable in the appropriate locations
	# (example $PATH on UNIX).
	#
	# This function caches its result both in memory and between Rub runs.  Feel
	# free to call it often.
	#
	# @param cmd [String]    The name of the command (basename only).
	# @return [Pathname,nil] Pathname, or nil if not found.
	#
	# @example
	#   C::find_command 'true'    #=> #<Pathname:/usr/bin/true>
	#   C::find_command 'cc'      #=> #<Pathname:/home/kevincox/.local/bin/cc>
	#   C::find_command 'sl'      #=> #<Pathname:/usr/bin/sl>
	#   C::find_command 'python'  #=> #<Pathname:/usr/bin/python>
	#   C::find_command 'explode' #=> nil
	def self.find_command(cmd)
		exe = R.spersistant["C.find_command.#{cmd}"]
		
		exe and exe.executable? and return exe

		exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
		names = exts.map{|e| cmd+e}
		ENV['PATH'].split(File::PATH_SEPARATOR)
		           .map{|d|Pathname.new(d)}
		           .each do |d|
			names.each do |n|
				e = d + n
				#p e
				
				if e.executable?
					exe = e
					break
				end
			end
			
			exe and break
		end
		
		R.spersistant["C.find_command.#{cmd}"] = exe
	end
end

D.resolve_path(:prefix, "/usr/local/")
