namespace :js_client do
  desc 'pull in testTrack JS Client and move to app/assets/javascripts'
  task :pull do
    sh 'bower install'
    sh 'mv', 'bower_components/test_track_js_client/dist/testTrack.bundle.min.js', 'app/assets/javascripts'
  end
end
