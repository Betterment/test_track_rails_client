$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "ruby_spec_helpers/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name = "ruby_spec_helpers"
  s.version = RubySpecHelpers::VERSION
  s.authors = ["Development"]
  s.email = ["development@betterment.com"]
  s.summary = "Spec configuration helpers for Betterment"
  s.description = "Spec configuration helpers for Betterment"

  s.files = Dir["lib/**/*", "README.md"]

  s.add_dependency "capybara"
  s.add_dependency "selenium-webdriver"
  s.add_dependency "site_prism"
  s.add_dependency "rspec-rails"
  s.add_dependency "yarjuf"
  s.add_dependency "webmock", '~> 2.1' #avoid ruby 2.0 dependency
  s.add_dependency "rubocop", '< 0.42' #avoid ruby 2.0 dependency
  s.add_dependency "rspec-retry", "~> 0.4.5"
end
