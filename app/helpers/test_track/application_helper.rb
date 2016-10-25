module TestTrack::ApplicationHelper
  def test_track_setup_tag
    state_json_base64 = Base64.strict_encode64(test_track_session.state_hash.to_json)
    javascript_tag("window.TT = '#{state_json_base64}';")
  end
end
