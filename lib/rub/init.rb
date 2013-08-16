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

require 'pathname'
require 'pp'

#$LOAD_PATH.push(Pathname.new(__FILE__).realpath.dirname.to_s)

require_relative 'modules'
require_relative 'version'
require_relative 'tool'

require_relative 'define'
require_relative 'environment'
require_relative 'commandline'
require_relative 'dirs'
require_relative 'persist'
require_relative 'runner'

require_relative 'target'
require_relative 'targetgenerator'

require_relative 'c'
require_relative 'help'

##### Add the first two scripts.
R::Runner.do_file(R::Env.src_dir+"root.rub")
R::Runner.do_file(R::Env.cmd_dir+"dir.rub")

ARGV.empty? and ARGV << ':all'

ARGV.each do |t|
	t = if t =~ /^:[^\/]*$/ # Is a tag.
		t[1..-1].to_sym
	else
		C.path(t)
	end
	R::get_target(t).build
end
