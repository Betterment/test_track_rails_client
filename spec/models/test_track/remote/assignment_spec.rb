require 'rails_helper'

RSpec.describe TestTrack::Remote::Assignment do
  let(:params) { { visitor_id: "fake_visitor_id", split: "button_color", variant: "blue", mixpanel_result: "success" } }
  let(:url) { "http://dummy:fakepassword@testtrack.dev/api/assignment" }

  subject { described_class.new(params) }

  before do
    stub_request(:post, url).to_return(status: 204, body: "")
  end

  it "doesn't hit the remote in test mode" do
    expect(subject.save).to eq true
    expect(WebMock).not_to have_requested(:post, url)
  end

  it "hits the server when enabled" do
    with_env(TEST_TRACK_ENABLED: true) { subject.save }
    expect(WebMock).to have_requested(:post, url).with(body: params.to_json)
  end

  describe "validation" do
    it "validates visitor_id" do
      assignment = described_class.new(params.except(:visitor_id))
      expect(assignment).not_to be_valid
      expect(assignment.errors).to be_added(:visitor_id, "can't be blank")
    end

    it "validates split" do
      assignment = described_class.new(params.except(:split))
      expect(assignment).not_to be_valid
      expect(assignment.errors).to be_added(:split, "can't be blank")
    end

    it "validates variant" do
      assignment = described_class.new(params.except(:variant))
      expect(assignment).not_to be_valid
      expect(assignment.errors).to be_added(:variant, "can't be blank")
    end

    it "validates mixpanel_result" do
      assignment = described_class.new(params.except(:mixpanel_result))
      expect(assignment).not_to be_valid
      expect(assignment.errors).to be_added(:mixpanel_result, "can't be blank")
    end
  end
end
