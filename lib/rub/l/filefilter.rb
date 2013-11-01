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

# File filter functions.
module L::FileFilter
	
	# Generated Filters get put in here.
	module Filters
	end
	
	# Create a file filter.
	# 
	# A file filter is a type of target that depends only on its input and
	# output files (and possibly it's arguments).
	# 
	# @param name [String] The name of this filter.  Think of it as a class name,
	#                      for example, `Head` or `Cat`.
	# @param filter The function to run.  It is given two `Set`s, inputs and
	#               outputs, and any arguments after that.
	# @return A function that creates the targets, it takes the same arguments
	#         as are passed to `filter`.
	def self.make_filter(name, &filter)
		t = Class.new(R::TargetSmart) do
			def initialize(filter, src, dest, *args)
				super()
				
				@filter = filter
				@src    = src
				@dest   = dest
				@args   = args
				
				input .merge src
				output.merge dest
				
				register
			end
			
			def hash_input
				Digest::SHA1.digest(super+C.chash(@args)+C.chash(@kwargs))
			end
			
			def build_self
				output.each{|o| o.dirname.mkpath}
				
				bs = @filter.call(@src, @dest, *@args)
				if not bs.is_a?(R::BuildStep)
					bs = nil
				end
				
				bs      ||=  R::BuildStep.new
				if bs.desc.empty?
					bs.desc = "Rendering #{output.to_a.join', '}"
				end
				bs.print
			end
		end
		L::FileFilter::Filters.const_set("TargetFilter#{name}", t)
		
		return Proc.new do |src, dest, *args|
			src  = R::Tool::make_array_paths src
			dest = R::Tool::make_set dest
			dest.map!{|d| R::Env.out_dir+'l/filefilter/'+C.unique_segment(args)+d}
			
			t.new(filter, src, dest, *args)
			
			return dest
		end
	end
	
	# Copy the first lines from a file.
	# 
	# Copies the first `lines` lines from each file in `src` to each file in
	# `dest`.
	# 
	# @param src  [Set<Pathname>] The source files.
	# @param dest [Set<Pathname>] The output files.
	# @param lines The number of lines to copy from each `src`.
	# @return The output files.
	def self.head(src, dest, lines); end
	
	@head = make_filter 'Head' do |src, dest, lines|
		src.uniq!
		outs = dest.map {|f| f.open('w')}
		
		src.each do |f|
			f.open do |io|
				(1..lines).each do |_|
					s = io.gets
					if not s
						break
					end
					
					outs.each do |o|
						o.puts(s)
					end
				end
			end
		end
		
		outs.each{|o| o.close}
	end
	singleton_class.send :define_method, 'head', @head
	
	# Concatenate files.
	# 
	# @param src    [Array<Pathname>] The files to concatenate.
	# @param dest   [Set<Pathname>]   The output files.
	# @return [Set<Pathname>]   The output files.
	def self.cat(src, dest); end
	
	@cat = make_filter 'Cat' do |src, dest|
		outs = dest.map {|f| f.open('w')}
		
		src.each do |f|
			s = f.read
			
			outs.each do |o|
				o.write s
			end
		end
		
		outs.each{|o| o.close}
	end
	singleton_class.send :define_method, 'cat', @cat
end
