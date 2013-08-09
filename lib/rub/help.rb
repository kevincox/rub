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
require 'singleton'

module R
	class TargetHelp < C::TargetTag
		@@tag = nil
		def gen_help
			@@tag and return
			
			@@tag = Set.new
			@@bld = Set.new
			@@ins = Set.new
			@@src = Set.new
			
			R.targets.each do |p, t|
				if p.is_a? Symbol
					@@tag << [p, t]
				elsif p.to_s.start_with?(R::Env.out_dir.to_s)
					@@bld << [p, t]
				elsif (
						p.to_s.start_with?(D[:prefix].to_s+'/') ||
					   !p.to_s.start_with?(R::Env.src_dir.to_s)
					  )
					@@ins << [p, t]
				else
					@@src << [p, t]
				end
			end
		end
		
		def initialize(t)
			super t.to_sym
			
			register
		end
		
		def print_target(ta)
			p, t = ta
			ps = if p.is_a? Symbol
				#p.inspect
				":#{p}"
			else
				p.to_s
			end
			
			if t.description
				printf "  %-20s - %s\n", ps, t.description
			else
				printf "  %s\n", ps
			end
		end
		
		def print_targets(tm)
			tm.each do |t|
				print_target t
			end
		end
		
		def build
			gen_help
		end
	end
	
	class TargetHelpHelp < TargetHelp
		include Singleton
		
		def initialize
			super :help
		end
		
		def build
			super
			
			puts <<'EOS'
Help:
  Just displaying tags.  If you want to see more see:
    :help-tag
    :help-installed
    :help-built
    :help-all
EOS
			R.get_target('help-tag'.to_sym).build
		end
	end
	TargetHelpHelp.instance
	
	class TargetHelpTag < TargetHelp
		include Singleton
		
		def initialize
			super 'help-tag'
		end
		
		def build
			super
		
			puts 'Tags:'
			print_targets @@tag
		end
	end
	TargetHelpTag.instance
	
	class TargetHelpInstalled < TargetHelp
		include Singleton
		
		def initialize
			super 'help-installed'
		end
		
		def build
			super
		
			puts 'Installed:'
			print_targets @@ins
		end
	end
	TargetHelpInstalled.instance
	
	class TargetHelpBuilt < TargetHelp
		include Singleton
		
		def initialize
			super 'help-built'
		end
		
		def build
			super
		
			puts 'Build Targets:'
			print_targets @@bld
		end
	end
	TargetHelpBuilt.instance
	
	class TargetHelpAll < TargetHelp
		include Singleton
		
		def initialize
			super 'help-all'
		end
		
		def build
			super
			
			[
				'help-tag',
				'help-installed',
				'help-built',
			].each{|t| R.get_target(t.to_sym).build }
		end
	end
	TargetHelpAll.instance
	
end
