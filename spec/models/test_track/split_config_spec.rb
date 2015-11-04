require 'rails_helper'

RSpec.describe TestTrack::SplitConfig do
  let(:params) { { name: "my_split", weighting_registry: { foo: 25, bar: 75 } } }
  let(:url) { "http://dummy:fakepassword@testtrack.dev/api/split_config" }

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
