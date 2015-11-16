require 'rails_helper'

RSpec.describe TestTrack::SplitRegistry do
  let(:split_registry) { { 'time' => { 'back_in_time' => 100, 'power_of_love' => 0 } } }

  before do
    allow(described_class).to receive(:instance).and_call_original
    allow(described_class).to receive(:fake_instance_attributes).and_return(split_registry)
    Rails.cache.clear
  end

  describe "#to_hash" do
    it "only hits the API once" do
      2.times { expect(described_class.to_hash).to eq(split_registry) }
      expect(described_class).to have_received(:instance).exactly(:once)
    end

    it "freezes the returned hash even when retrieving from cache" do
      2.times { expect { described_class.to_hash[:foo] = "bar" }.to raise_error(/frozen/) }
    end

    it "returns nil if the server times out" do
      allow(described_class).to receive(:instance) { raise(Faraday::TimeoutError, "too slow!") }

      expect(described_class.to_hash).to eq(nil)

      expect(described_class).to have_received(:instance)
    end

    it "returns nil if the server 503s" do
      allow(described_class).to receive(:instance) { raise(Her::Errors::RemoteServerError, "503 is happening") }

      expect(described_class.to_hash).to eq(nil)

      expect(described_class).to have_received(:instance)
    end
  end
end
