module TestTrackRails
  module ApplicationHelper
    def test_track_setup_tag
      javascript_tag(render(partial: 'test_track_rails/setup.js.erb').chomp)
    end

    def tt_split_registry_json
      raw(tt_split_registry.to_json) # rubocop:disable Betterment/Raw
    end

    def tt_assignment_registry_json
      raw(tt_assignment_registry.to_json) # rubocop:disable Betterment/Raw
    end
  end
end
