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

# Support for using libraries that use pkg-config.
module L::PkgConfig
	def self.find
		C.find_command 'pkg-config'
	end
	
	def self.run(pkg)
		pkey = "L::PkgConfig.pkg-#{pkg}"
		if R.spersistant[pkey]
			return R.spersistant[pkey]
		end
		
		r = {
			include: [],
			define: {},
			cflags: [],
			
			libs: [],
			lflags: [],
		}
		
		v = R::Command.new [find, '--modversion', pkg]
		f = R::Command.new [find, '--cflags', pkg]
		l = R::Command.new [find, '--libs',   pkg]
		v.start; f.start; l.start
		
		v.block
		r[:versionstr] = v.stdout.chomp
		r[:version]    = Gem::Version.new(r[:versionstr])
		
		f.block
		fa = f.stdout.split' '
		fa.each do |a|
			case a[1]
			when 'I'
				r[:include] << a[2..-1]
			when 'D'
				/(?<k>[^=]*)=(?<v>.*)/ =~ a
				r[:define][k] = v
			else
				r[:cflags] << a
			end
		end
		
		l.block
		la = l.stdout.split' '
		la.each do |a|
			case a[1]
			when 'l'
				r[:libs] << a[2..-1]
			else
				r[:lflags] << a
			end
		end
		
		R.spersistant[pkey] = r
	end
	
	def self.apply(cx, ld, pkg, ver=nil)
		p = self.run(pkg)
		if ver
			v = Gem::Requirement.new ver
			if not v =~ p[:version]
				raise "Available version #{p[:version]} does not satisfy #{ver}"
			end
		end
		
		if cx
			cx.define.merge!       p[:define]
			cx.include_dirs.concat p[:include]
			#cx.flags.concat        p[:cflags]
			pp cx.libs
			pp cx.libs.class
			cx.libs.concat         p[:libs]
			pp cx.libs
		end
		
		if ld
			ld.args.concat       p[:lflags]
		end
	end
end
