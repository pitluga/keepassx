# frozen_string_literal: true

require_relative 'lib/keepassx/version'

Gem::Specification.new do |s|
  s.name        = 'keepassx'
  s.version     = Keepassx::VERSION
  s.authors     = ['Tony Pitluga', 'Paul Hinze']
  s.email       = ['tony.pitluga@gmail.com', 'paul.t.hinze@gmail.com']
  s.homepage    = 'http://github.com/pitluga/keepassx'
  s.summary     = 'Ruby API access for KeePassX databases'
  s.description = 'See http://github.com/pitluga/keepassx'
  s.license     = 'MIT'

  s.files = `git ls-files`.split("\n")

  s.add_development_dependency 'factory_bot'
  s.add_development_dependency 'guard-rspec'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'respect'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'simplecov'
end
