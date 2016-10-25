require 'rails_helper'

RSpec.describe TestTrack::Remote::IdentifierType do
  let(:params) { { name: "myappdb_user_id" } }
  let(:url) { "http://testtrack.dev/api/v1/identifier_type" }

  subject { described_class.new(params) }

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
    expect(WebMock).to have_requested(:post, url).with(body: params.to_json)
  end
end
