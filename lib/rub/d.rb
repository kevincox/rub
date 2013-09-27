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

# Definitions Namespace.
module D
	@@map = {}
	
	# Define a configuration option.
	#
	# @param k [String] The key, or if +v+ is nil a string to parse.
	# @param v [String,nil] The value
	# @return [String] The value.
	#
	# If +v+ is non-nil +k+ is the key and +v+ is the value.  If +v+ is nil
	# k must be a string and it is parsed to find the key and value.
	#
	# - If there is an '=' in +k+ the first one is used.
	#   - If the '=' is proceeded by a '+' everything before the "+=" is used as
	#     the key and everything after is used as the value.  These are then
	#     passed are passed onto #push.
	#   - Otherwise everything before the '=' is used as the key and everything
	#     after as the value.
	#   - If there is no '=' all of +k+ is used as the key and the value is
	#     +true+.
	#
	# The key will be converted into a symbol and the k/v pair will be added to
	# the configuration options.
	#
	# @example
	#   D.define('k1', 'v1')
	#   D[:k1] #=> "v1"
	#   D.define('k2=v2')
	#   D[:k2] #=> "v2"
	#   D.define('k3')
	#   D[:k3] #=> true
	#   D.define('k4')
	#   D[:k4] #=> true
	#   D.define('k4=')
	#   D[:k4] #=> ""
	#   D.define('k5+=v5')
	#   D.define('k5+=v6')
	#   D[:k5] #=> ["v5", "v6"]
	#   
	#   D.define('w1=v1=v2')
	#   D[:w1] #=> "v1=v2"
	#   D.define('w2=v2+=v3')
	#   D[:w2] #=> "v2+=v3"
	def self.define(k, v=nil)
		if v == nil
		
			k, f, v = k.partition '='
			
			if    k.end_with?('+') and not f.empty?
				return append(k[0..-2], v)
			elsif k.end_with?('^') and not f.empty?
				return prepend(k[0..-2], v)
			end
		end
		
		k = k.to_sym
		
		if f == ""
			v = true
		end
		
		@@map[k] = v
	end
	class << self
		alias_method '[]=', :define
	end
	
	# Append a configuration option onto a value.
	#
	# @param k [String] The key, or if +v+ is nil a string to parse.
	# @param v [String,nil] The value
	# @return [String] The value.
	#
	# If +v+ is non-nil +k+ is the key and +v+ is the value.  If +v+ is nil
	# k must be a string and it is parsed to find the key and value.
	#
	# If there is a '=' in the string everything before the first '=' is used as
	# the key and everything after the value.  If the key ends is '+' it is
	# dropped.  If there is no '=' +k+ is used as the key and +true+ as the
	# value.
	#
	# @example
	#   D.append('k1', 'v1')
	#   D[:k1] #=> ["v1"]
	#   D.append('k1', 'v2')
	#   D[:k1] #=> ["v1", "v2"]
	#   D.append('k2=v3')
	#   D.append('k2+=v4')
	#   D.append('k2+=')
	#   D[:k2] #=> ["v3", "v4", ""]
	#   
	#   D.append('w1+')
	#   D[:w1]   #=> nil
	#   D['w1+'] #=> [true]
	def self.append(k, v=nil)
		if v == nil
			k, f, v = k.partition '='
			
			if k.end_with?('+') and not f.empty?
				k = k[0..-2]
			end
		end
		
		k = k.to_sym
		
		if f == ''
			v = true
		end
		
		@@map[k].is_a?(Array) or (
			@@map[k] = ( @@map[k].nil? ? [] : [@@map[k]] )
		)
		
		@@map[k].push(v)
	end
	
	# Prepend a configuration option onto a value.
	#
	# @param k [String] The key, or if +v+ is nil a string to parse.
	# @param v [String,nil] The value
	# @return [String] The value.
	#
	# If +v+ is non-nil +k+ is the key and +v+ is the value.  If +v+ is nil
	# k must be a string and it is parsed to find the key and value.
	#
	# If there is a '=' in the string everything before the first '=' is used as
	# the key and everything after the value.  If the key ends is '^' it is
	# dropped.  If there is no '=' +k+ is used as the key and +true+ as the
	# value.
	#
	# @example
	#   D.prepend('k1', 'v1')
	#   D[:k1] #=> ["v1"]
	#   D.prepend('k1', 'v2')
	#   D[:k1] #=> ["v2", "v1"]
	#   D.prepend('k2=v3')
	#   D.prepend('k2^=v4')
	#   D.prepend('k2+=')
	#   D[:k2] #=> ["", "v4", "v3",]
	#   
	#   D.prepend('w1^')
	#   D[:w1]   #=> nil
	#   D['w1^'] #=> [true]
	def self.prepend(k, v=nil)
		if v == nil
			k, f, v = k.partition '='
			
			if k.end_with?('^') and not f.empty?
				k = k[0..-2]
			end
		end
		
		k = k.to_sym
		
		if f == ''
			v = true
		end
		
		@@map[k].is_a?(Array) or (
			@@map[k] = ( @@map[k].nil? ? [] : [@@map[k]] )
		)
		
		@@map[k].unshift(v)
	end
	
	# Retrieve a defined value.
	#
	# @param k [Symbol,String] The key.
	def self.[] (k)
		@@map[k.to_sym]
	end
	
	# Return the configuration map.
	#
	# This is intended for debugging only and may be removed/made private any
	# time.
	#
	# See: #pp
	def self.map
		return @@map
	end
	
	# Pretty Print the configuration options.
	#
	# Useful for debugging.
	def self.pp
		pp map
	end
	
	# Read definitions from a file.
	#
	# @deprecated
	#
	# These are read one-per-line and passed to #define (as one argument).
	def self.fromFile(fn)
		File.open(fn) {|f| f.each_line {|l| define(l.chomp) } }
	end
	
	# Resolve a path.
	#
	# This makes a passed in path proper.  This function must be used in order
	# to make paths passed in on the command line proper.  This makes all paths
	# relative to the directory where the command was executed.  If the
	# definition was not provided it is set to default, no path resolution is
	# done on the default value.
	#
	# @param k [Symbol,String] The key of the option.
	# @param default [Object] The value to use if +k+ is not set.
	def self.resolve_path(k, default=nil)
		k = k.to_sym
		
		@@map[k] = if @@map[k] != nil
			Pathname.new(@@map[k]).expand_path(R::Env.cmd_dir)
		else
			default
		end
	end
end

# Alias for D.[]
#
# @see D.[]
#
# @example
#   D.define 'k1=v1'
#   D.define 'k2=v2'
#   D :k1 #=> "v1"
#   D:k2  #=> "v2"
def D(k)
	D[k]
end
