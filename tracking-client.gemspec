# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'tracking-client/version'

Gem::Specification.new do |gem|
  gem.name          = "tracking-client"
  gem.version       = Tracking::Client::VERSION
  gem.authors       = ["Thorben Schröder"]
  gem.email         = ["thorben@quarterspiral.com"]
  gem.description   = %q{A client to track events}
  gem.summary       = %q{This is a thin wrapper around an actual tracking library, tailored to the Quarter Spiral use case}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency 'uuidtools', '~> 2.1.3'
  gem.add_dependency 'uuid', '~> 2.3.7'
  gem.add_dependency 'minuteman', '~> 1.0.2'
  gem.add_dependency 'hiredis', "~> 0.4.5"
end
