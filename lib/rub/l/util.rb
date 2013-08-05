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

require 'singleton'

D.resolve_path :pefix

# General purpose build tools.
module L::Util
	class TargetUninstall < C::TargetTag
		include Singleton
		
		def initialize
			super :uninstall
			@files = Set.new
			
			register
		end
		
		def add(f)
			f = R::Tool.make_set_paths f
			
			@files.merge f
			
			f
		end
		
		def build
			R::run(['rm', '-fv']+@files.to_a, "Removing installed files.", importance: :med)
		end
	end
	TargetUninstall.instance.description = 'Remove installed targets.' # Make the target.
	
	# Uninstall a file.
	#
	# Adds the file to the :uninstall tag.
	#
	# @param what [Set<Pathname,String>,Array<Pathname,String>,Pathname,String]
	#             The files to remove.
	# @return [void]
	def self.uninstall(what)
		what = R::Tool.make_set_paths what
		
		what.each do |f|
			TargetUninstall.instance.add f
		end
	end

	# Install a file.
	#
	# Installs +what+ into the directory +where+.  Source files are added to
	# the +=all+ tag and installed files are added to the +=install+ tag.
	#
	# @param what [Set<Pathname,String>,Array<Pathname,String>,Pathname,String]
	#             The files to install.
	# @param where [Pathname,String] The directory to install them to.  If not
	#                                absolute it is relative to +D:prefix+
	# @return [Array<Pathname>] The installed files.
	# 
	# @example
	#   exe = L::C.program(srcs, ['pthread'], 'bitmonitor-test')
	#   L::Util.install exe, 'bin/'
	#
	def self.install(what, where)
		what = R::Tool.make_set_paths what
		where = Pathname.new(where).expand_path(D :prefix)
		
		at = ::C.tag :all
		it = ::C.tag :install
		
		what.map do |f|
			if f.directory?
				install(f.children, where+f.basename)
			else
				out = where+f.basename
				::C.generator(f, ['install', "-D", f, out], out, desc: "Installing").each do |o|
					at.require(f)
					it.require(o)
				end
				uninstall out
				
				out
			end
		end.flatten.to_set
	end
end
