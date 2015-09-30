require 'rails_helper'

RSpec.describe TestTrackRails::IdentifierType do
  let(:params) { { name: "bettermentdb_user_id" } }
  let(:url) { "http://dummy:fakepassword@testtrack.dev/identifier_type" }

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
end
