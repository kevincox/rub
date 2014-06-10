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

# Version info.
module R::Version
	# Pretty Program Name.
	def self.name
		'Rub'
	end
	
	# Short easy-to-type name.
	def self.stub
		'rub'
	end
	
	# Command name.
	def self.slug
		stub + R::Version.version_major
	end
	
	# Version number as a list.
	#
	# Returns a list of three elements with the major, minor and patch numbers
	# respectively.
	def self.version
		[version_major, version_minor, version_patch]
	end
	
	# Returns the version number as a string.
	def self.number_string
		version.join('.')
	end
	
	# Latest tag and current commit.
	def self.version_commit
		number_string + '.' + commit[0,8]
	end
	
	# Commit and if it is dirty.
	def self.commit_dirty
		commit + ( dirty? ? '-dirty' : '' )
	end
	
	# If the version information has been prerendered.
	#
	# If this is false dirty information is probably pretty accurate.  If this
	# is true they might have been changed since the rendering occurred.
	def self.rendered?
		false
	end
	
	# Returns a version string in the format of the +--version+ command switch.
	def self.info_string
		"#{slug} (#{name}) #{string}"
	end
	
	# Returns a formatted version string.
	def self.string
		a = []
		
		a << number_string
		if dist_from_tag > 0
			a << dist_from_tag
			a << "g#{commit[0,8]}"
		end
		
		if dirty?
			a << 'dirty'
		end
		
		a.join '-'
	end
	
	# Return a string describing the current version.
	#
	# Returns an overly verbose string giving all useful (and more) information
	# about the current state of the source.
	def self.verbose
		out = []
		
		out << "You are using Rub, a platform and language independent build system.\n"
		out << "https://github.com/kevincox/rub\n"
		
		out << "\n"
		
		out << "You are using commit #{commit}"
		if dirty?
			out << " but the source you are running has been modified since then"
		end
		out << ".\n"
		
		out << "Commit #{commit[0,8]} is"
		if dist_from_tag > 0
			out << " #{dist_from_tag} commits after"
		end
		out << " version #{number_string}.\n"
		
		if rendered?
			out << "\n"
			out << "NOTE: This information was accurate at the time of"
			out << " installation.  Rub can not detect changes since then."
		end
		
		out.join
	end
end

R::VersionPure = R::Version.dup

cwd = Pathname.new(__FILE__).realpath.dirname

`cd '#{cwd}'; git rev-parse --git-dir > /dev/null 2>&1`
ingit = $?.exitstatus == 0

if cwd.join('version-git.rb').exist? && ingit
	#puts 'Loading git'
	load cwd.join('version-git.rb').to_s
elsif cwd.join('version-generated.rb').exist?
	#puts 'Loading generated'
	load cwd.join('version-generated.rb').to_s
else
	raise "Couldn't find version info!"
	Sysexits.exit :software
end
