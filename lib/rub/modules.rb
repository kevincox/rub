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

# Core Module
#
# Contains core Rub functions.
module C

end

# Define Module
#
# All configuration options are gathered here.
module D

end

# Library Module
#
# Loaded libraries become available here.
module L
	# Auto-load libraries.
	def self.const_missing(n)
		#pp n
		p = "l/#{n.to_s.downcase}"
		
		require_relative p
		const_defined?(n, false) or raise "Library #{p} malformed, was expected to load into L::#{n}."
		const_get(n, false)
	end
end

# Rub internals.
#
# Internal functions intended for library developers only.  Eventually
# this will be only for Rub itself and the functions for library developers will
# be moved into {C}.
module R

end
