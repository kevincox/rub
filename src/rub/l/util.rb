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

D.resolve_path :pefix

module L
	module Util
		def self.install(what, where)
			what = R::Tool.make_array what
			
			what.map!{|f| Pathname.new(f).expand_path}
			where = Pathname.new(where).expand_path(D[:prefix])
			
			it = ::C.tag('=install')
			
			what.map do |f|
				f.directory? or next f
			
				c = []
				f.find do |e|
					e.file? and c << e
				end
				c
			end
			what.flatten!
			what.each do |f|
				out = where+f.basename
				::C.generator(f, ['install', "-D", f, out], out, desc: "Installing").each do |o|
					it.require(o)
				end
			end
		end
	end
end
