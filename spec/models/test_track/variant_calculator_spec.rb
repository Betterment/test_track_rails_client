require 'rails_helper'

RSpec.describe TestTrack::VariantCalculator do
  let(:params) { { visitor: visitor, split_name: 'blue_button' } }

  let(:visitor) { instance_double(TestTrack::Visitor, id: fake_visitor_id, split_registry: split_registry) }

  let(:fake_visitor_id) { "00000000-0000-0000-0000-000000000000" }

  let(:split_registry) { TestTrack::SplitRegistry.new(split_registry_hash) }
  let(:split_registry_hash) do
    {
      'splits' => {
        'blue_button' => {
          'weights' => {
            'true' => 60,
            'false' => 40
          },
          'feature_gate' => false
        }
      },
      'experience_sampling_weight' => 1
    }
  end

  subject { described_class.new(params) }

  it "requires split_name" do
    expect { described_class.new(params.except(:split_name)) }.to raise_error(/split_name/)
  end

  it "requires visitor" do
    expect { described_class.new(params.except(:visitor)) }.to raise_error(/visitor/)
  end

  it "rejects unknown opts" do
    expect { described_class.new(params.merge(foo: "bar")) }.to raise_error(/foo/)
  end

  describe "#split_visitor_hash" do
    it "calculates MD5 of split_name and visitor id" do
      # Digest::MD5.new.update("blue_button00000000-0000-0000-0000-000000000000").hexdigest => "d694064e4ebe3c24c0950556b371829a"
      expect(subject.split_visitor_hash).to eq "d694064e4ebe3c24c0950556b371829a"
    end
  end

  describe "#hash_fixnum" do
    it "converts 00000000deadbeef into 0" do
      allow(subject).to receive(:split_visitor_hash).and_return("00000000deadbeef")
      expect(subject.hash_fixnum).to eq 0
    end

    it "converts 0000000fdeadbeef into 15" do
      allow(subject).to receive(:split_visitor_hash).and_return("0000000fdeadbeef")
      expect(subject.hash_fixnum).to eq 15
    end

    it "converts ffffffffdeadbeef into 4294967295" do
      allow(subject).to receive(:split_visitor_hash).and_return("ffffffffdeadbeef")
      expect(subject.hash_fixnum).to eq 4_294_967_295
    end
  end

  describe "#assignment_bucket" do
    it "puts 0 in bucket 0" do
      allow(subject).to receive(:hash_fixnum).and_return(0)
      expect(subject.assignment_bucket).to eq 0
    end

    it "puts 99 in bucket 99" do
      allow(subject).to receive(:hash_fixnum).and_return(99)
      expect(subject.assignment_bucket).to eq 99
    end

    it "puts 100 in bucket 0" do
      allow(subject).to receive(:hash_fixnum).and_return(100)
      expect(subject.assignment_bucket).to eq 0
    end

    it "puts 4294967295 in bucket 95" do
      allow(subject).to receive(:hash_fixnum).and_return(4_294_967_295)
      expect(subject.assignment_bucket).to eq 95
    end
  end

  describe "#sorted_variants" do
    it "sorts variants alphabetically" do
      expect(subject.sorted_variants).to eq %w(false true)
    end
  end

  describe "#weighting" do
    it "returns the weighting hash for a split" do
      expect(subject.weighting).to eq('true' => 60, 'false' => 40)
    end

    it "blows up if the split doesn't exist" do
      expect { described_class.new(params.merge(split_name: 'nonexistent')).weighting }.to raise_error(/nonexistent.*not found/)
    end
  end

  describe "#variant" do
    context "with a nil split_registry" do
      let(:split_registry_hash) { nil }

      it "returns nil if split registry isn't present" do
        expect(subject.variant).to eq nil
      end
    end

    context "in logo_size split" do
      let(:split_registry_hash) do
        {
          'splits' => {
            'logo_size' => {
              'weights' => {
                'extra_giant' => 0,
                'giant' => 80,
                'huge' => 1,
                'leetle' => 0,
                'miniscule' => 19,
                'teeny' => 0
              },
              'feature_gate' => false
            }
          },
          'experience_sampling_weight' => 1
        }
      end

      subject { described_class.new(params.merge(split_name: 'logo_size')) }

      it "returns the first variant with non-zero weight from bucket 0" do
        allow(subject).to receive(:assignment_bucket).and_return(0)
        expect(subject.variant).to eq "giant"
      end

      it "returns the last variant with non-zero weight from bucket 99" do
        allow(subject).to receive(:assignment_bucket).and_return(99)
        expect(subject.variant).to eq "miniscule"
      end

      it "returns the correct 1%-wide variant" do
        allow(subject).to receive(:assignment_bucket).and_return(80)
        expect(subject.variant).to eq "huge"
      end
    end

    context "with an incomplete weighting" do
      let(:split_registry_hash) do
        {
          'splits' => {
            'invalid_weighting' => {
              'weights' => {
                'yes' => 33,
                'maybe' => 33,
                'no' => 33
              },
              'feature_gate' => false
            }
          },
          'experience_sampling_weight' => 1
        }
      end

      subject { described_class.new(params.merge(split_name: 'invalid_weighting')) }

      it "blows up when it runs out of variants before hitting our bucket" do
        allow(subject).to receive(:assignment_bucket).and_return(99)
        expect { subject.variant }.to raise_error(/Assignment bucket/)
      end
    end
  end
end
