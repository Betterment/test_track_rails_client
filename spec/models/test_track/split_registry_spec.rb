require 'rails_helper'

RSpec.describe TestTrack::SplitRegistry do
  subject { described_class.new(registry_hash) }

  let(:registry_hash) do
    {
      'splits' => {
        'button_size' => {
          'weights' => {
            'one' => 50,
            'two' => 50
          },
          'feature_gate' => 'false'
        },
        'time' => {
          'weights' => {
            'hammertime' => 100,
            'clobberin_time' => 0
          },
          'feature_gate' => 'false'
        }
      },
      'experience_sampling_weight' => 1
    }
  end

  describe ".from_remote" do
    context "with a server response" do
      before do
        allow(TestTrack::Remote::SplitRegistry).to receive(:to_hash).and_return(registry_hash)
      end

      it "returns an instance populated with a remote hash" do
        split_registry = described_class.from_remote

        expect(split_registry).to be_an_instance_of(TestTrack::SplitRegistry)
        expect(split_registry.loaded?).to eq(true)
        expect(TestTrack::Remote::SplitRegistry).to have_received(:to_hash)
      end
    end

    context "with a nil hash" do
      before do
        allow(TestTrack::Remote::SplitRegistry).to receive(:to_hash).and_return(nil)
      end

      it "returns an instance populated with a remote hash" do
        split_registry = described_class.from_remote

        expect(split_registry).to be_an_instance_of(TestTrack::SplitRegistry)
        expect(split_registry.loaded?).to eq(false)
        expect(TestTrack::Remote::SplitRegistry).to have_received(:to_hash)
      end
    end
  end

  describe "#include?" do
    it "returns true when a split with the given name is present in the registry" do
      expect(subject.include?('time')).to eq true
      expect(subject.include?('not_time')).to eq false
    end
  end

  describe "#loaded?" do
    context "when registry is present" do
      it "returns true" do
        expect(subject.loaded?).to eq true
      end
    end

    context "when no registry is available" do
      let(:registry_hash) { nil }

      it "returns false" do
        expect(subject.loaded?).to eq false
      end
    end
  end

  describe "#split_names" do
    it "returns list of split names" do
      expect(subject.split_names).to contain_exactly('button_size', 'time')
    end
  end

  describe "#experience_sampling_weight" do
    it "returns sampling weight provided by server" do
      expect(subject.experience_sampling_weight).to eq(1)
    end
  end

  describe "#weights_for" do
    it "returns weights for the given split" do
      expect(subject.weights_for('time')).to eq("clobberin_time" => 0, "hammertime" => 100)
      expect(subject.weights_for('no_time')).to eq(nil)
    end
  end

  describe "#to_v1_hash" do
    it "returns a hash compatible with v1 split registry endpoint" do
      expect(subject.to_v1_hash).to eq(
        "button_size" => {
          "one" => 50,
          "two" => 50
        },
        "time" => {
          "clobberin_time" => 0,
          "hammertime" => 100
        }
      )
    end
  end
end
