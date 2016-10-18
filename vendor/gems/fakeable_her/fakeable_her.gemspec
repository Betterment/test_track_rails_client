# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fakeable_her/version'

Gem::Specification.new do |spec|
  spec.name          = "fakeable_her"
  spec.version       = FakeableHer::VERSION
  spec.authors       = ["Development"]
  spec.email         = ["development@betterment.com"]

  spec.summary       = "Her for testing locally"
  spec.description   = "Her for testing locally"
  spec.homepage      = "https://github.com/betterment/better-core"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'her'
  spec.add_dependency 'rails', '~> 4.1'

  spec.add_development_dependency 'rubocop', '>= 0.36'
end
