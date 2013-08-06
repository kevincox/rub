require 'getoptlong'
require 'sysexits'

require 'rub/define'

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

# Command line parsing and handling.
module R::CommandLine
	help = lambda do
				puts <<ENDHELP
#{R.version_info_string}

Usage: #{$0} [options] [targets]

Targets:
Specify the targets to build.  If none are specified '=all' is assumed.

Options:
-o --out <dir>
	Sets the Rub build directory.  This defaults to 'build/'.  This is
	merely a scratch location and none of the files in this directory should
	be used outside of Rub.  You may want to put this on fast storage (maybe
	in RAM) to speed up complex builds.
-D, --define <key>[=<value>]
	Define a configuration option.  The key is everything up to the first
	'=' and the value is everything after.  If the key ends in '+' it is
	treated as a '-P'.  If there is no '=' it is treated as a flag and it
	is set.  Latter '-D' options overwrite earlier ones.
-D, --define <key>+=<value>
-P, --push   <key>[+=<value>]
-P, --push   <key>[=<value>]
	Append a configuration option to a list.  If the current value is not
	a list it is overwritten.  The key and value specification is the same
	as for '-D' except that a '+' is not nessary and is assumed.
--script <script>
	Run a script.  This script should only set define options as all of Rub
	may not be initilized yet.  The script is executed in order with other
	'--script', '-D' and '-P' options.
--explicit-scripts
	Only run scripts specified on the command line.  This prevents system
	and user defaults from being used.  Use with caution because it could
	cause a build to fail if the provided definitions don't contain enough
	information.
--no-cache
	Disable caching.  All state from previous runs will be discarded.  Caching
	will still be performed inside a single run.
-V, --version
	Print the version and exit.
-h, --help
	Print this help text and exit.
ENDHELP
		exit
	end
	
	class << self
		attr_reader :cache
	end
	@cache = true

	opts = GetoptLong.new(
		['--out',    '-o',                      GetoptLong::REQUIRED_ARGUMENT ],
		['-D', '--define',                      GetoptLong::REQUIRED_ARGUMENT ],
		['-P', '--push',                        GetoptLong::REQUIRED_ARGUMENT ],
		['--script',                            GetoptLong::REQUIRED_ARGUMENT ],
		['--explicit-scripts',                  GetoptLong::NO_ARGUMENT       ],
		['--no-cache',                          GetoptLong::NO_ARGUMENT       ],
		['--help',    '-h',                     GetoptLong::NO_ARGUMENT       ],
		['--version', '-V', '-v',               GetoptLong::NO_ARGUMENT       ],
		['--version-number',                    GetoptLong::NO_ARGUMENT       ],
		['--version-describe',                  GetoptLong::NO_ARGUMENT       ],
		['--version-verbose',                   GetoptLong::NO_ARGUMENT       ],
		['--version-version-commit',            GetoptLong::NO_ARGUMENT       ],
	)
	
	scripts = [];
	sysscripts = [
		[:file, Pathname.new("/etc/rub/config.rb")],
		[:file, Pathname.new(Dir.home())+".config/rub/config.rb"],
	].keep_if { |t, n| n.exist? }
	
	opts.each do |opt, arg|
		case opt
			when '--out'
				Rub::Env.out_dir = Rub::Env.cmd_dir + arg
			when '-D'
				scripts.push [:define, arg]
			when '-P'
				scripts.push [:push,   arg]
			when '--script'
				scripts.push [:file,   Pathname(arg)]
			when '--explicit-scripts'
			when '--no-cache'
				@cache = false
				sysscripts = []
			when '--version'
				puts R::Version.info_string
				exit 0
			when '--version-number'
				puts R::Version.number_string
				exit 0
			when '--version-describe'
				puts R::Version.string
				exit 0
			when '--version-verbose'
				puts R::Version.verbose
				exit 0
			when '--version-version-commit'
				puts R::Version.version_commit
				exit 0
			when '--help'
				help.call
		end
	end
	
	sysscripts.concat(scripts).each do | t, a |
		case t
			when :file
				if not a.exist?
					$stderr.puts "Can't load defines from \"#{a}\" because it doesn't exist!"
					Sysexits.exit :noinput
				end
			
				load a
			when :define
				D.define(a)
			when :push
				D.push(a)
		end
	end
end

