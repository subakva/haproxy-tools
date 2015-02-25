# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'haproxy/version'

Gem::Specification.new do |gem|
  gem.name          = 'haproxy-tools'
  gem.version       = HAProxy::VERSION
  gem.authors       = ['Jason Wadsworth']
  gem.email         = ['jdwadsworth@gmail.com']
  gem.description   = %q{Ruby tools for HAProxy, including config file management.}
  gem.summary       = %q{HAProxy Tools for Ruby}
  gem.homepage      = 'https://github.com/subakva/haproxy-tools'
  gem.license = 'MIT'

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.required_ruby_version = '>= 1.9.3'

  gem.add_dependency('net-scp')
  gem.add_dependency('treetop')
  gem.add_development_dependency('rake')
  gem.add_development_dependency('rspec', '~> 2.14')
  gem.add_development_dependency('yard')
  gem.add_development_dependency('simplecov')
  gem.add_development_dependency('cane')
  # gem.add_development_dependency('pry-debugger')
end
