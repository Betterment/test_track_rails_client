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

  let(:split_registry) do
    {
      'button_color' => {
        'red' => 50,
        'blue' => 50
      },
      'button_size' => {
        'one' => 100,
        'two' => 0,
        'three' => 0,
        'four' => 0
      }
    }
  end

  before do
    allow(Airbrake).to receive(:notify_or_ignore).and_call_original
  end

  describe "#initialize" do
    it "raises when missing a split_name" do
      expect do
        described_class.new initialize_options.except(:split_name)
      end.to raise_error("Must provide split_name")
    end

    it "raises when missing a true_variant" do
      expect do
        described_class.new initialize_options.except(:true_variant)
      end.to raise_error("Must provide true_variant")
    end

    it "raises when missing a split_registry" do
      expect do
        described_class.new initialize_options.except(:split_registry)
      end.to raise_error("Must provide split_registry")
    end

    it "raises when given an unknown option" do
      expect do
        described_class.new initialize_options.merge(unwelcome: "option")
      end.to raise_error("unknown opts: unwelcome")
    end

    it "allows a nil split_registry" do
      expect do
        described_class.new initialize_options.merge(split_registry: nil)
      end.not_to raise_error
    end
  end

  describe "#variants" do
    it "should only have true and false keys" do
      expect(subject.variants.keys).to eq [:true, :false]
    end

    it "tells airbrake if there are more than two variants" do
      ab_configuration = described_class.new initialize_options.merge(split_name: :button_size)
      ab_configuration.variants
      expect(Airbrake).to have_received(:notify_or_ignore).with("A/B for \"button_size\" configures split with more than 2 variants").exactly(:once)
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

      it "is false when there is no split_registry" do
        ab_configuration = described_class.new initialize_options.merge(split_registry: nil)
        expect(ab_configuration.variants).to include(false: false)
      end

      it "is always the same if the split has more than two variants" do
        ab_configuration = described_class.new initialize_options.merge(split_name: :button_size, true_variant: :one)
        expect(ab_configuration.variants).to include(false: "four")
      end
    end
  end
end
