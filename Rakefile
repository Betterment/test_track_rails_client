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

APP_RAKEFILE = File.expand_path("../spec/dummy/Rakefile", __FILE__)
load 'rails/tasks/engine.rake'

Bundler::GemHelper.install_tasks

require 'rspec/core'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RSpec::Core::RakeTask.new
RuboCop::RakeTask.new

desc "Pull the latest versions of all dependencies into the gem for distribution"
task :vendor_deps do
  # Bundle minified JS client
  sh 'bower install'
  sh 'cp', 'bower_components/test_track_js_client/dist/testTrack.bundle.min.js', 'app/assets/javascripts'

  # Download testtrack-cli
  TEST_TRACK_CLI_VERSION = 'v0.9.7'
  FileUtils.module_eval do
    mkdir_p 'vendor/bin/testtrack-cli'
    cd 'vendor/bin/testtrack-cli' do
      rm_r Dir.glob('*')

      %w(darwin linux).each do |arch|
        `curl -L https://github.com/Betterment/testtrack-cli/releases/download/#{TEST_TRACK_CLI_VERSION}/testtrack.#{arch} \
          > testtrack.#{arch}`
          chmod 0755, "testtrack.#{arch}"
      end
    end
  end

  # Gems
  FileUtils.module_eval do
    cd "vendor/gems" do
      rm_r Dir.glob('*')
      %w(her fakeable_her).each do |repo|
        `git clone --depth=1 git@github.com:Betterment/#{repo}.git && rm -rf #{repo}/.git`
      end
    end

    cd "vendor/gems/her" do
      rm_r(Dir.glob('.*') - %w(. ..))
      rm_r Dir.glob('*.md')
      rm_r %w(
        Appraisals
        Gemfile
        Gemfile.lock
        Rakefile
        gemfiles
        spec
      ), force: true
    end

    cd "vendor/gems/fakeable_her" do
      rm_r(Dir.glob('.*') - %w(. ..))
      rm_r Dir.glob('*.md')
      rm_r %w(
        Appraisals
        Gemfile
        Gemfile.lock
        Rakefile
        bin
        gemfiles
        spec
      ), force: true
      `sed -E -i '' '/license/d' fakeable_her.gemspec`
      `sed -E -i '' '/homepage/d' fakeable_her.gemspec`
    end
  end
end

task(:default).clear
if ENV['APPRAISAL_INITIALIZED'] || ENV['TRAVIS']
  task default: %i(rubocop spec)
else
  require 'appraisal'
  Appraisal::Task.new
  task default: :appraisal
end
