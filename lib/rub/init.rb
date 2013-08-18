#! /usr/bin/env ruby

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

##### These libraries are guaranteed to be loaded.
require 'pathname'
require 'set'
require 'pp'
require 'digest/sha1'

require 'sysexits'
require 'xdg'

##### Load the namespaces.
require_relative 'd'
require_relative 'r'
require_relative 'l'
require_relative 'c'

##### Parse the command line.
require_relative 'commandline'
require_relative 'dirs'
require_relative 'persist'
require_relative 'help'

##### Add the first two scripts.
R::Runner.do_file(R::Env.src_dir+"root.rub")
R::Runner.do_file(R::Env.cmd_dir+"dir.rub")

##### Add default target if necessary.
ARGV.empty? and ARGV << ':all'

##### Build requested targets.
ARGV.each do |t|
	t = if t =~ /^:[^\/]*$/ # Is a tag.
		t[1..-1].to_sym
	else
		C.path(t)
	end
	R::get_target(t).build
end

