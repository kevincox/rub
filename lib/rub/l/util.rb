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
	
	# Create a link
	#
	# @param target   [Pathname,String] The file the link points to.
	# @param name     [Pathname,String] The location of the link.
	# @param type          [:sym,:hard] The type of link to create.
	# @param expand_target [true,false] Whether or not to make target an
	#                                   absolute path.  This allows the creation
	#                                   of relative links.
	# @return [Pathname] The path of the link.
	def self.link(target, name, type = :sym, expand_target: true)
		target = expand_target ? C.path(target) : target
		name   = C.path name
		
		C.generator(
			[], #target,
			['ln', '-f', (type == :sym ? '-s' : nil), target, name].compact,
			name,
			desc: 'Linking'
		)
		name
	end
	
	# Install a file to a specific location.
	# 
	# @see #install
	#
	# Similar to {#install} but the basename is not used as the name in the new
	# location.  If from is a dirtectory it is installed and renamed but it's
	# contents are preserved with the same names.
	#
	# @param from [Set<Pathname,String>,Array<Pathname,String>,Pathname,String]
	#             The files to install.
	# @param to [Pathname,String] Where to install them.  If not
	#                                absolute it is relative to +D:prefix+
	# @param mode [Numeric] The permissions (specified in base ten) for the
	#                       file.  If nil the current permissions are kept.
	# @param require [Set<Pathname,String>,Array<Pathname,String>,Pathname,String]
	#                Files that must be present before installing the file.  
	# @return [Array<Pathname>] The installed files.
	def self.install_to(from, to, mode: nil, require: [])
		from = C.path(from)
		to   = Pathname.new(to).expand_path(D :prefix)
		
		if from.directory?
			return install(from.children, to)
		end
		
		C.generator(
			Set[from].merge(require),
			['install', "-D#{mode!=nil ? "m#{mode}" : "" }", from, to],
			to,
			desc: 'Installing'
		).each do |o|
			C.tag(:all    ).require(from)
			C.tag(:install).require(to)
		end
		uninstall to
		
		Set[from]
	end
	
	# Install a file
	#
	# Installs +what+ into the directory +where+.  Source files are added to
	# the +=all+ tag and installed files are added to the +=install+ tag.
	#
	# @param what [Set<Pathname,String>,Array<Pathname,String>,Pathname,String]
	#             The files to install.
	# @param where [Pathname,String] The directory to install them to.  If not
	#                                absolute it is relative to +D:prefix+
	# @param mode [Numeric] The permissions (specified in base ten) for the
	#                       file.  If nil the current permissions are kept.
	# @param require [Set<Pathname,String>,Array<Pathname,String>,Pathname,String]
	#                Files that must be present before installing the file.  
	# @return [Array<Pathname>] The installed files.
	# 
	# @example
	#   exe = L::C.program(srcs, ['pthread'], 'bitmonitor-test')
	#   L::Util.install exe, 'bin/', mode: 755
	#
	def self.install(what, where, mode: nil, require: [])
		what = R::Tool.make_set_paths what
		where = Pathname.new(where)
		require = R::Tool.make_set_paths require
		
		what.map do |f|
			if f.directory?
				install(f.children, where+f.basename)
			else
				install_to(f, where+f.basename)
			end
		end.flatten.to_set
	end
end
