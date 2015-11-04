module TestTrack::ApplicationHelper
  def test_track_setup_tag
    state_json_base64 = Base64.strict_encode64(test_track_session.state_hash.to_json)
    js = javascript_tag("window.TT = '#{state_json_base64}';")
    content_tag(:div, js, class: '_tt', style: 'visibility:hidden;width:0;height:0;')
  end
end
