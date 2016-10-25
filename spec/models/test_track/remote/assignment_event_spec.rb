require 'rails_helper'

RSpec.describe TestTrack::Remote::AssignmentEvent do
  let(:params) do
    {
      visitor_id: "fake_visitor_id",
      split_name: "button_color",
      context: "the_context",
      mixpanel_result: "success"
    }
  end
  let(:url) { "http://testtrack.dev/api/v1/assignment_event" }

  subject { described_class.new(params) }

  let(:existing_assignment) { described_class.find("fake_assignment_id") }

  before do
    stub_request(:post, url)
      .with(basic_auth: %w(dummy fakepassword))
      .to_return(status: 204, body: "")
  end

  it "doesn't hit the remote in test mode" do
    expect(subject.save).to eq true
    expect(WebMock).not_to have_requested(:post, url)
  end

  it "hits the server when enabled" do
    with_test_track_enabled { subject.save }
    expect(WebMock).to have_requested(:post, url).with(body: params.except(:mixpanel_result).merge(mixpanel_result: "success").as_json)
  end

  describe "validation" do
    it "validates visitor_id" do
      assignment = described_class.new(params.except(:visitor_id))
      expect(assignment).not_to be_valid
      expect(assignment.errors).to be_added(:visitor_id, "can't be blank")
    end

    it "validates split" do
      assignment = described_class.new(params.except(:split_name))
      expect(assignment).not_to be_valid
      expect(assignment.errors).to be_added(:split_name, "can't be blank")
    end

    it "validates mixpanel_result" do
      assignment = described_class.new(params.except(:mixpanel_result))
      expect(assignment).not_to be_valid
      expect(assignment.errors).to be_added(:mixpanel_result, "can't be blank")
    end
  end
end
