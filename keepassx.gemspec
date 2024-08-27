# frozen_string_literal: true

require_relative 'lib/keepassx/version'

Gem::Specification.new do |s|
  s.name        = 'keepassx'
  s.version     = Keepassx::VERSION::STRING
  s.authors     = ['Tony Pitluga', 'Paul Hinze']
  s.email       = ['tony.pitluga@gmail.com', 'paul.t.hinze@gmail.com']
  s.homepage    = 'http://github.com/pitluga/keepassx'
  s.summary     = 'Ruby API access for KeePassX databases'
  s.description = 'See http://github.com/pitluga/keepassx'
  s.license     = 'MIT'

  s.required_ruby_version = '>= 2.6.0'

  s.files = `git ls-files`.split("\n")

  s.add_dependency 'zeitwerk'
end
