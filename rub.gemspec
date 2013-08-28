Gem::Specification.new do |s|
	s.name        = 'rub'
	s.version     = `cd #{File.dirname(__FILE__).inspect}; ruby bin/rub.rb --version-number`.chomp
	s.date        = '2010-04-28'
	s.summary     = 'A platform and language independent build system.'
	s.description = 'A platform and language independent build system.'
	s.authors     = ['Kevin Cox']
	s.email       = 'kevincox@kevincox.ca'
	s.files       = Dir['lib/**/*.rb']
	s.executables << 'rub.rb'
	s.homepage    = 'https://github.com/kevincox/rub'
	s.license     = 'zlib'
	
	s.add_runtime_dependency 'sysexits',    '>=0'
	s.add_runtime_dependency 'xdg',         '>=0'
	s.add_runtime_dependency 'valid_array', '>=0'
	
	# Kinda optional.
	s.add_runtime_dependency 'minitest', '>=5'
end
