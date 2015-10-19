module TestTrackRails
  module ApplicationHelper
    def test_track_setup_tag
      js = javascript_tag(render(partial: 'test_track_rails/setup.js.erb').chomp)
      content_tag(:div, js, class: '_tt', style: 'visibility:hidden;width:0;height:0;')
    end

    def tt_split_registry_json
      raw(tt_split_registry.to_json) # rubocop:disable Betterment/Raw
    end

    def tt_assignment_registry_json
      raw(tt_assignment_registry.to_json) # rubocop:disable Betterment/Raw
    end
  end
end
