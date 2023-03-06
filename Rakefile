begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

require 'rdoc/task'

RDoc::Task.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'TestTrackRailsClient'
  rdoc.options << '--line-numbers'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

APP_RAKEFILE = File.expand_path('spec/dummy/Rakefile', __dir__)
load 'rails/tasks/engine.rake'

Bundler::GemHelper.install_tasks

require 'rspec/core'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RSpec::Core::RakeTask.new
RuboCop::RakeTask.new

desc "Pull the latest versions of all dependencies into the gem for distribution"
task :vendor_deps do
  test_track_js_client_version = '2.0.0'.freeze
  test_track_cli_version = 'v1.2.0'.freeze

  # Bundle JS client
  sh 'npm init -y'
  sh "npm install --no-save test_track_js_client@#{test_track_js_client_version}"
  sh 'cp', 'node_modules/test_track_js_client/dist/testTrack.bundle.js', 'app/assets/javascripts/testTrack.bundle.min.js'
  sh 'rm package.json'

  # Download testtrack-cli
  FileUtils.module_eval do
    mkdir_p 'vendor/bin/testtrack-cli'
    cd 'vendor/bin/testtrack-cli' do
      rm_r Dir.glob('*')

      %w(darwin linux).each do |arch|
        `curl -L https://github.com/Betterment/testtrack-cli/releases/download/#{test_track_cli_version}/testtrack.#{arch} \
          > testtrack.#{arch}`
        chmod 'u=wrx,go=rx', "testtrack.#{arch}"
      end
    end
  end
end

task(:default).clear
if ENV['APPRAISAL_INITIALIZED'] || ENV['CI']
  task default: %i(rubocop spec)
else
  require 'appraisal'
  Appraisal::Task.new
  task default: :appraisal
end
