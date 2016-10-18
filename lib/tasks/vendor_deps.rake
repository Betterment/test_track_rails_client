namespace :test_track_rails_client do
  task :vendor_deps do
    FileUtils.module_eval do
      cd "vendor/gems" do
        rm_r Dir.glob('*')
        %w(ruby_spec_helpers her fakeable_her).each do |repo|
          `git clone --depth=1 git@github.com:Betterment/#{repo}.git && rm -rf #{repo}/.git`
        end
      end

      cd "vendor/gems/ruby_spec_helpers" do
        rm_r(Dir.glob('.*') - %w(. ..))
        rm_r Dir.glob('*.md')
        rm_r %w(
          Gemfile
          Gemfile.lock
          spec
        ), force: true
        `sed -E -i '' '/license/d' ruby_spec_helpers.gemspec`
      end

      cd "vendor/gems/fakeable_her" do
        rm_r(Dir.glob('.*') - %w(. ..))
        rm_r Dir.glob('*.md')
        rm_r %w(
          Gemfile
          Gemfile.lock
          Rakefile
          bin
          spec
        ), force: true
        `sed -E -i '' '/license/d' fakeable_her.gemspec`
      end
    end
  end
end
