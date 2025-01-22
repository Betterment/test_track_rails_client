$LOAD_PATH.push File.expand_path('lib', __dir__)

# Maintain your gem's version:
require "test_track_rails_client/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "test_track_rails_client"
  s.version     = TestTrackRailsClient::VERSION
  s.authors     = ["Ryan O'Neill", "Alex Burgel", "Adam Langsner", "John Mileham", "Alan Norton", "Sam Moore"]
  s.email       = ["ryan.oneill@betterment.com"]
  s.homepage    = "https://github.com/Betterment"
  s.summary     = "Rails client for TestTrack"
  s.description = "Easy split testing and feature flagging for Rails with TestTrack server"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib,vendor}/**/*", "LICENSE", "Rakefile", "README.md"]

  s.add_dependency 'activejob', '>= 7.0'
  s.add_dependency 'activemodel', '>= 7.0'
  s.add_dependency "faraday", ">= 0.8"
  s.add_dependency 'faraday_middleware'
  s.add_dependency 'mixpanel-ruby', '~> 1.4'
  s.add_dependency 'multi_json', '~> 1.7'
  s.add_dependency 'public_suffix', '>= 2.0.0'
  s.add_dependency 'railties', '>= 5.1'
  s.add_dependency 'request_store', '~> 1.3'
  s.add_dependency 'sprockets-rails'

  s.add_development_dependency 'appraisal'
  s.add_development_dependency 'betterlint'
  s.add_development_dependency 'pry-rails'
  s.add_development_dependency 'rails-controller-testing'
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'shoulda-matchers', '>= 2.8'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'timecop'
  s.add_development_dependency 'webmock'

  s.required_ruby_version = '>= 3.2'
end
