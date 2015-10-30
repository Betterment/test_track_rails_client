module TestTrackRails
  module ApplicationHelper
    def test_track_setup_tag
      state_hash = {
        url: TestTrackRails.url,
        cookieDomain: test_track_session.cookie_domain,
        registry: test_track_visitor.split_registry,
        assignments: test_track_visitor.assignment_registry
      }
      state_json_base64 = Base64.strict_encode64(state_hash.to_json)
      js = javascript_tag("window.TT = '#{state_json_base64}';")
      content_tag(:div, js, class: '_tt', style: 'visibility:hidden;width:0;height:0;')
    end
  end
end
