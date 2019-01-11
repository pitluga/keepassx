# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'keepassx/version'

Gem::Specification.new do |s|
  s.name        = 'keepassx'
  s.version     = Keepassx::VERSION
  s.authors     = ['Tony Pitluga', 'Paul Hinze']
  s.email       = ['tony.pitluga@gmail.com', 'paul.t.hinze@gmail.com']
  s.homepage    = 'http://github.com/pitluga/keepassx'
  s.summary     = 'Ruby API access for KeePassX databases'
  s.description = 'See http://github.com/pitluga/keepassx'

  s.add_development_dependency 'factory_girl'
  s.add_development_dependency 'guard'
  s.add_development_dependency 'guard-rspec'
  s.add_development_dependency 'rake', '~> 10.4'
  s.add_development_dependency 'respect'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'simplecov'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ['lib']
end
