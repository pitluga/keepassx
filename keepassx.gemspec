Gem::Specification.new do |s|
  s.name = "keepassx"
  s.summary = "Ruby API access for KeePassX databases"
  s.description = "See http://github.com/pitluga/keepassx"
  s.version = "0.1.0"
  s.authors = ["Tony Pitluga", "Paul Hinze"]
  s.email = ["tony.pitluga@gmail.com", "paul.t.hinze@gmail.com"]
  s.homepage = "http://github.com/pitluga/keepassx"
  s.files = `git ls-files`.split("\n")

  s.add_dependency "fast-aes", "~> 0.1"

  s.add_development_dependency "rspec", "2.11.0"
end
