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

require 'date'

# Core Module
module C
	# Expand a path.
	#
	# @return [Pathname]
	def self.path(p)
		p.is_a? Symbol and return p
		
		#p = case p[0]
		#	when '!'
		#		Pathname.new(p[1..-1])
		#	when '>'
		#		R::Env.out_dir + p[1..-1]
		#	when '<'
		#		R::Env.src_dir + p[1..-1]
		#	else
		#		Pathname.new(p)
		#end
		
		Pathname.new(p).expand_path
	end
	
	# Glob pathnames.
	#
	# @see Dir.glob
	#
	# @param glob [String]
	# @return [Set<Pathname>]
	def self.glob(glob)
		Set.new Dir.glob(glob).map{|e| C.path(e) }
	end
	
	# Get a consistant hash of an object.
	def self.chash(o)
		if o.is_a? Array
			return o.map{|i| chash i}.join
		end
		
		# Super hacky, strip out object-ids, because they change every
		# invocation, but use inspect.  It works alright.
		r = o.inspect.gsub(/(?<!:):0x[0-9a-f]*/, '')
		
		# Modules don't print themselfs meaningfully.
		if o.is_a? Module
			r << o.pretty_print_instance_variables.map{|k| [k, o.instance_variable_get(k)] }.inspect
		end
	
		r	
	end
	
	# Create a probably unique path segment.
	#
	# Creates a string in the form '$stuff/' that will probably be unique.
	#
	# @param seed [Object] A value to use for the folder name, keeping this the
	#                      same across invocations allows predictable names,
	#                      preventing unnecessary rebuilds.
	def self.unique_segment(*seed)
		seed ||= caller_locations(1,1)
		
		return Digest::SHA1.hexdigest(chash(seed))
	end
	
	# Return a probably unique file name.
	#
	# This file can be used as a build target.
	#
	# @param base [String] The basename of the file.
	# @param seed [Object] A value to use for the folder name, keeping this the
	#                      same across invocations allows predictable names,
	#                      preventing unnecessary rebuilds.
	def self.unique_path(base, seed)
		R::Env.out_dir + 'c/unique/' + unique_segment(seed) + base
	end
	
	# Tag Target
	#
	# This is the target used for tags.
	class TargetTag < R::Target
		attr_reader :output, :input
		attr_reader :tag
		
		attr_accessor :description
		
		# Create a TargetTag
		#
		# @param t [Symbol] the name of the tag.
		def initialize(t)
			t.is_a? Symbol or raise 'Targets can be created with symbols only.'
		
			@tag = t
			@output = Set[t]
			@input  = Set[]
		end
		
		# Add a target to this tag.
		#
		# @param f [Pathname,String] The path of the target.
		def require(f)
			f = R::Tool.make_set f
			f.map!{|e| C.path(e)}
			
			input.merge(f)
		end
		
		def build
			input.each{|i| R::get_target(i).build }
		end
	end
	
	# Tag class
	#
	# Manages a tag.  This should not be created buy the user but retrieved from
	# {C.tag}.
	class Tag
		# The tag's name.
		# @return [Symbol]
		attr_accessor :name
		
		def description
			@target.description
		end
		def description=(d)
			@target.description = d
		end
		
		# Create a Tag
		#
		# @param t [Symbol] the name of the tag.
		def initialize(t)
			@name = t
			@target = TargetTag.new(t)
			@target.register
		end
		
		# Add a target to this tag.
		#
		# @param f [Pathname,String] The path of the target.
		def require(f)
			@target.require f
		end
	end
	
	# Get a tag.
	#
	# If the tag already exists it returns the existing {Tag} object otherwise
	# it creates and returns a new {Tag} instance.
	#
	# @param t [Symbol] The tag name.
	# @return [Tag]     The tag object.
	def self.tag(t)
		R.find_target(t) || Tag.new(t)
	end
	
	##### Create default tags.
	tag(:all)    .description = 'All targets.'
	tag(:install).description = 'Install the project.'
	tag(:none)   .description = 'Do nothing.'
	
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
		
		src = R::Tool.make_set_paths(src)
		out = R::Tool.make_set_paths(out)
		cmd[0].is_a?(Array) or cmd = [cmd]
		
		t.input .merge(src)
		t.output.merge(out)
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
		pn = Pathname.new(cmd)
		if pn.absolute?
			#return pn.executable? ? pn : nil
			return pn
		end
		
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
