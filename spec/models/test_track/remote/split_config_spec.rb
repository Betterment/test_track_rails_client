require 'rails_helper'

RSpec.describe TestTrack::Remote::SplitConfig do
  let(:params) { { name: "my_split", weighting_registry: { foo: 25, bar: 75 } } }
  let(:create_url) { "http://testtrack.dev/api/split_configs" }
  let(:destroy_url) { "http://testtrack.dev/api/split_configs/some_split" }

  subject { described_class.new(params) }

  before do
    stub_request(:post, create_url).to_return(status: 204, body: "")
    stub_request(:delete, destroy_url).to_return(status: 204, body: "")
  end

  describe "#save" do
    it "doesn't hit the remote in test mode" do
      expect(subject.save).to eq true
      expect(WebMock).not_to have_been_requested
    end

    it "hits the server when enabled" do
      with_test_track_enabled { subject.save }
      expect(WebMock).to have_requested(:post, create_url).with(body: params.to_json)
    end
  end

  describe ".destroy_existing" do
    it "doesn't hit the remote in test mode" do
      described_class.destroy_existing(:some_split)
      expect(WebMock).not_to have_been_requested
    end

    it "hits the server when enabled" do
      with_test_track_enabled { described_class.destroy_existing(:some_split) }
      expect(WebMock).to have_requested(:delete, destroy_url)
    end
  end
end
