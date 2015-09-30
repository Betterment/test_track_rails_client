$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "test_track_rails/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "test_track_rails"
  s.version     = TestTrackRails::VERSION
  s.authors     = ["TODO: Your name"]
  s.email       = ["TODO: Your email"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of TestTrackRails."
  s.description = "TODO: Description of TestTrackRails."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "rails", "~> 4.1.11"

  s.add_development_dependency "sqlite3"
end
