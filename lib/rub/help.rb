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

module R
	class TargetHelp < C::TargetTag
		HELP_HELP      = 'help-help'     .to_sym
		HELP_TAG       = 'help-tag'      .to_sym
		HELP_INSTALLED = 'help-installed'.to_sym
		HELP_BUILT     = 'help-built'    .to_sym
		
		HELP           = 'help'          .to_sym
		HELP_ALL       = 'help-all'      .to_sym
		
		@@map = {
			HELP_HELP      => 1<<0,
			HELP_TAG       => 1<<1,
			HELP_INSTALLED => 1<<2,
			HELP_BUILT     => 1<<3,
		}
		@@map[HELP]     = @@map[HELP_HELP] | @@map[HELP_TAG]
		@@map[HELP_ALL] = @@map[HELP_TAG] | @@map[HELP_INSTALLED] | @@map[HELP_BUILT]
		
		def self.gen_help
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
			
			TargetHelp.new(HELP_HELP).register
			TargetHelp.new(HELP_TAG).register
			TargetHelp.new(HELP_INSTALLED).register
			TargetHelp.new(HELP_BUILT).register
			
			TargetHelp.new(HELP).register
			TargetHelp.new(HELP_ALL).register
		end
		
		def initialize(t)
			super
		end
		
		def print_target(ta)
			p, t = ta
			ps = if p.is_a? Symbol
				p.inspect
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
			if @@map[tag] & @@map[HELP_HELP.to_sym] != 0
				puts <<'EOS'
Help:
  Just displaying tags.  If you want to see more see:
   - :help-tag
   - :help-installed
   - :help-built
   - :help-all
EOS
			end
			if @@map[tag] & @@map[HELP_TAG.to_sym] != 0
				puts 'Tags:'
				print_targets @@tag
			end
			if @@map[tag] & @@map[HELP_INSTALLED.to_sym] != 0
				puts 'Install Targets:'
				print_targets @@ins
			end
			if @@map[tag] & @@map[HELP_BUILT.to_sym] != 0
				puts 'Build Targets:'
				print_targets @@bld
			end
		end
	end
end
