namespace :js_client do
  task pull: :environment do
    sh 'bower install'
    sh 'mv', 'bower_components/test_track_js_client/dist/testTrack.bundle.min.js', 'app/assets/javascripts'
  end
end
