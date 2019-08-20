require 'rails_helper'

RSpec.describe TestTrack::ABConfiguration do
  subject do
    described_class.new initialize_options
  end

  let(:initialize_options) do
    {
      split_name: :button_color,
      true_variant: :red,
      split_registry: split_registry
    }
  end

  let(:split_registry) { TestTrack::SplitRegistry.new(split_registry_hash) }
  let(:split_registry_hash) do
    {
      'splits' => {
        'button_color' => {
          'weights' => {
            'red' => 50,
            'blue' => 50
          },
          'feature_gate' => false
        },
        'button_size' => {
          'weights' => {
            'one' => 100,
            'two' => 0,
            'three' => 0,
            'four' => 0
          },
          'feature_gate' => false
        }
      },
      'experience_sampling_weight' => 1
    }
  end

  let(:notifier) { instance_double(TestTrack::MisconfigurationNotifier::Wrapper, notify: nil) }

  before do
    allow(TestTrack).to receive(:misconfiguration_notifier).and_return(notifier)
  end

  describe "#initialize" do
    it "raises when missing a split_name" do
      expect {
        described_class.new initialize_options.except(:split_name)
      }.to raise_error("Must provide split_name")
    end

    it "raises when missing a true_variant" do
      expect {
        described_class.new initialize_options.except(:true_variant)
      }.to raise_error("Must provide true_variant")
    end

    it "raises when missing a split_registry" do
      expect {
        described_class.new initialize_options.except(:split_registry)
      }.to raise_error("Must provide split_registry")
    end

    it "raises when given an unknown option" do
      expect {
        described_class.new initialize_options.merge(unwelcome: "option")
      }.to raise_error("unknown opts: unwelcome")
    end

    it "raises when given a nil split_registry" do
      expect {
        described_class.new initialize_options.merge(split_registry: nil)
      }.to raise_error("Must provide split_registry")
    end

    it "raises a descriptive error when the split is not in the split_registry" do
      expect {
        described_class.new initialize_options.merge(split_name: :not_a_real_split)
      }.to raise_error("unknown split: not_a_real_split.")
    end

    context 'when in the development environment' do
      it 'gives a suggested fix' do
        with_rails_env 'development' do
          expect {
            described_class.new initialize_options.merge(split_name: :not_a_real_split)
          }.to raise_error("unknown split: not_a_real_split. You may need to run rake test_track:schema:load")
        end
      end
    end

    context 'when in production' do
      it 'does not give a suggested fix' do
        with_rails_env 'production' do
          expect {
            described_class.new initialize_options.merge(split_name: :not_a_real_split)
          }.to raise_error("unknown split: not_a_real_split.")
        end
      end
    end
  end

  describe "#variants" do
    it "should only have true and false keys" do
      expect(subject.variants.keys).to eq %i(true false)
    end

    it "tells notifier if there are more than two variants" do
      ab_configuration = described_class.new initialize_options.merge(split_name: :button_size)
      ab_configuration.variants

      expected_msg = "A/B for \"button_size\" configures split with more than 2 variants"
      expect(notifier).to have_received(:notify).with(expected_msg).exactly(:once)
    end

    context "true variant" do
      it "is true if set to nil during instantiation" do
        ab_configuration = described_class.new initialize_options.merge(true_variant: nil)
        expect(ab_configuration.variants).to include(true: true)
      end

      it "is whatever was passed during instantiation" do
        expect(subject.variants).to include(true: "red")
      end
    end

    context "false variant" do
      it "is the variant of the split that is not the true_variant" do
        expect(subject.variants).to include(false: "blue")
      end

      it "is false when there is an unloaded split_registry" do
        ab_configuration = described_class.new initialize_options.merge(split_registry: TestTrack::SplitRegistry.new(nil))
        expect(ab_configuration.variants).to include(false: false)
      end

      it "is always the same if the split has more than two variants" do
        ab_configuration = described_class.new initialize_options.merge(split_name: :button_size, true_variant: :one)
        expect(ab_configuration.variants).to include(false: "four")
      end
    end
  end
end
