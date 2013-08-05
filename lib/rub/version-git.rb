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

require 'rub/modules'

module R::Version
	@@cdto = "cd '#{Pathname.new(__FILE__).realpath.dirname}'"
	@@regex = /^v([0-9]+)\.([0-9]+)\.([0-9]+)(-([0-9]+))?(-g([0-9a-f]+))?(-(dirty))?$/
	
	# Pretty Program Name.
	def self.name
		'Rub'
	end
	
	# Command name.
	def self.slug
		'rub'
	end
	
	def self.tag
		@@tagcache ||= `#{@@cdto}; git tag -l 'v[0-9]*.*.*'`.chomp
	end

	# Major version number.
	def self.version_major
		tag.sub @@regex, '\1'
	end
	# Minor version number.
	def self.version_minor
		tag.sub @@regex, '\2'
	end
	# Patch number.
	def self.version_patch
		tag.sub @@regex, '\3'
	end
	
	def self.revision?
		tag.sub @@regex, '\9'
	end
	
	def self.dirty?
		`#{@@cdto}; git diff --exit-code`
		$? != 0
	end
	
	def self.rendered?
		false
	end
	
	# Version number as a list.
	#
	# Returns a list of three elements with the major, minor and patch numbers
	# respectively.
	def self.version
		[version_major, version_minor, version_patch]
	end
	
	# Returns a formatted version string.
	def self.string
		`#{@@cdto}; git describe --always --dirty --match 'v[0-9]*.*.*'`.chomp.sub(/^v/, '')
	end

	# Returns a version string in the format of the +--version+ command switch.
	def self.info_string
		"#{slug} (#{name}) #{string}"
	end
end
