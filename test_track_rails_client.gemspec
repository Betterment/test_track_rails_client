$LOAD_PATH.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "test_track_rails_client/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "test_track_rails_client"
  s.version     = TestTrackRailsClient::VERSION
  s.authors     = ["John Mileham", "Alan Norton"]
  s.email       = ["john@betterment.com"]
  s.homepage    = "https://github.com/Betterment"
  s.summary     = "Rails client for TestTrack"
  s.description = "Easy split testing and feature flagging for Rails with TestTrack server and Mixpanel"
  s.license     = "All Rights Reserved"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency 'rails', '~> 4.1.11'
  s.add_dependency 'fakeable_her'
  s.add_dependency 'faraday_middleware'
  s.add_dependency 'public_suffix', '~> 1.4.6'
  s.add_dependency 'mixpanel-ruby', '~> 1.4'
  s.add_dependency 'delayed_job', '~> 4.0'
  s.add_dependency 'delayed_job_active_record'
  s.add_dependency 'airbrake', '~> 4.1'
  s.add_dependency 'delayed-plugins-airbrake'
  s.add_dependency 'request_store', '~> 1.2.1'

  s.add_development_dependency "pry-rails"
  s.add_development_dependency "timecop"
  s.add_development_dependency "rubocop", ">= 0.36"

  s.required_ruby_version = '>= 1.9.3'
end
