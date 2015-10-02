module TestTrackRails
  module ApplicationHelper
    def test_track_setup_tag
      javascript_tag(render partial: 'test_track_rails/setup.js.erb')
    end
  end
end
