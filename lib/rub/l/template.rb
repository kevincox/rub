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

require 'erb'
require 'ostruct'

# Templates for generating files.
module L::Template
	class Renderer < OpenStruct
		def render(template, filename: 'ERB String')
			t = ERB.new(template, nil, '-')
			t.filename = filename.to_s
			t.result(binding)
		end
		def render_file(f)
			f = C.path f
			
			render f.read, filename: f
		end
	end
	
	class TargetRenderer < R::TargetSmart
		def initialize(inp, out, values)
			super()
			
			@template = inp
			@resultf  = out
			
			if inp.is_a? Pathname
				input << inp
			end
			output << out
			
			@renderer = Renderer.new values
		end
		
		def build_self
			r = if @template.is_a? String
				@renderer.render @template
			else
				@renderer.render_file @template
			end
			
			@resultf.dirname.mkpath
			@resultf.open('w') do |f|
				f.write r
			end
			
			bs = R::BuildStep.new
			bs.desc = "Rendering #{@resultf}"
			bs.print
		end
	end
	
	# Generate a file from a template.
	# 
	# @param template [Pathname] The template to use.
	# @param out      [Set<Pathname>] The output path.
	# @param values [Hash] The values to use in the template.
	# @return [Set<Pathname>] The output files.
	def self.generate_file(inp, out, values={}); end
	
	@generate_file = L::FileFilter.make_filter 'Template' do |src, dest, values={}|
		if src.length > 1
			raise 'Source must be a single file.'
		end
		src  = src.first
		
		ctx = OpenStruct.new values
		
		t = ERB.new(src.read, nil, '-')
		t.filename = src.to_s
		r = t.result(binding)
		
		dest.each{|o| o.open('w'){|io| io.write r}}
	end
	singleton_class.send :define_method, 'generate_file', @generate_file
end
