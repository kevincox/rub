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

	# Pretty Program Name.
	def self.name
		'Rub'
	end
	
	# Command name.
	def self.slug
		'rub'
	end

	# Major version number.
	def self.version_major
		0
	end
	# Minor version number.
	def self.version_minor
		0
	end
	# Patch number.
	def self.version_patch
		0
	end

	# Version number as a list.
	#
	# Returns a list of three elements with the major, minor and patch numbers
	# respectively.
	def self.version
		[version_major, version_minor, version_patch]
	end
	
	# Returns a formatted version string.
	def self.version_string
		version.join('.')
	end

	# Returns a version string in the format of the +--version+ command switch.
	def self.version_info_string
		"#{slug} (#{name}) #{version_string}"
	end
end
