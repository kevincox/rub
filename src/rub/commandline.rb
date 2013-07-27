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

module Rub
	module CommandLine
		help = lambda do
					puts <<ENDHELP
rub ... help coming soon.
ENDHELP
			exit
		end
	
		opts = GetoptLong.new(
			['--help',    '-h', GetoptLong::NO_ARGUMENT ],
			['--version', '-V', GetoptLong::NO_ARGUMENT ],
			['-D', '--define',  GetoptLong::REQUIRED_ARGUMENT ],
			['-P', '--push',    GetoptLong::REQUIRED_ARGUMENT ],
			['--script',   GetoptLong::REQUIRED_ARGUMENT ],
			['--explicit-scripts', GetoptLong::NO_ARGUMENT ],
			['--out',    '-o', GetoptLong::REQUIRED_ARGUMENT ],
		)
		
		scripts = [];
		sysscripts = [
			[:file, Pathname.new(__FILE__).dirname+"config.rb"],
			[:file, Pathname.new("/etc/rub/config.rb")],
			[:file, Pathname.new(Dir.home())+".config/rub/config.rb"],
		].keep_if { |t, n| n.exist? }
		

		opts.each do |opt, arg|
			case opt
				when '--version'
					puts 'rub version 0'
					
				when '-D'
					scripts.push [:define, arg]
				when '-P'
					scripts.push [:push,   arg]
				when '--script'
					scripts.push [:file,   Pathname(arg)]
				when '--explicit-scripts'
					sysscripts = []
				when '--help'
					help.call
				when '--out'
					Rub::Env.out_dir = Rub::Env.cmd_dir + arg
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
end

