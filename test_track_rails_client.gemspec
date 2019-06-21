$LOAD_PATH.push File.expand_path("../lib", __FILE__)

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

  s.add_dependency 'delayed_job', '~> 4.0'
  s.add_dependency 'delayed_job_active_record'
  s.add_dependency "faraday", ">= 0.8", "< 1.0"
  s.add_dependency 'faraday_middleware'
  s.add_dependency 'mixpanel-ruby', '~> 1.4'
  s.add_dependency 'multi_json', '~> 1.7'
  s.add_dependency 'public_suffix', '>= 2.0.0', '<= 3.0.0'
  s.add_dependency 'rails', '>= 4.1', "< 6.0"
  s.add_dependency 'request_store', '~> 1.3'

  s.add_development_dependency 'appraisal', '~> 2.2.0'
  s.add_development_dependency "pry-rails"
  s.add_development_dependency "timecop"
  s.add_development_dependency "webmock", "~> 2.1.0"

  s.required_ruby_version = '>= 2.1.0'
end
