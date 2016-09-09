require 'rails_helper'

RSpec.describe TestTrack::CreateAliasJob do
  let(:params) { { existing_id: "fake_existing_id", alias_id: "fake_visitor_id" } }

  subject { described_class.new(params) }

  it "blows up with empty existing_id" do
    expect { described_class.new(params.merge(existing_id: '')) }
      .to raise_error(/existing_id/)
  end

  it "blows up with empty alias_id" do
    expect { described_class.new(params.merge(alias_id: nil)) }
      .to raise_error(/alias_id/)
  end

  it "blows up with unknown opts" do
    expect { described_class.new(params.merge(extra_stuff: true)) }
      .to raise_error(/unknown opts/)
  end

  describe "#perform" do
    before do
      allow(TestTrack.analytics).to receive(:alias)
    end

    it "sends analytics events" do
      with_test_track_enabled { subject.perform }
      expect(TestTrack.analytics).to have_received(:alias).with("fake_visitor_id", "fake_existing_id")
    end

    it "does not send analytics events when test is not enabled" do
      subject.perform
      expect(TestTrack.analytics).to_not have_received(:alias)
    end

    it "blows up if analytics.alias raises Timeout::Error" do
      allow(TestTrack.analytics).to receive(:alias) { raise Timeout::Error.new, "analytics alias failed" }
      expect do
        with_test_track_enabled { subject.perform }
      end.to raise_error("analytics alias failed")
    end
  end
end
