require 'rails_helper'

RSpec.describe TestTrack::Visitor do
  let(:new_visitor) { described_class.new }
  let(:existing_visitor) { described_class.new(id: existing_visitor_id) }
  let(:existing_visitor_id) { "00000000-0000-0000-0000-000000000000" }
  let(:assignment_registry) { { 'blue_button' => 'true', 'time' => 'waits_for_no_man' } }
  let(:split_registry) do
    {
      'blue_button' => {
        'false' => 50,
        'true' => 50
      },
      'quagmire' => {
        'untenable' => 50,
        'manageable' => 50
      },
      'time' => {
        'hammertime' => 100,
        'clobberin_time' => 0
      }
    }
  end

  before do
    allow(TestTrack::Remote::AssignmentRegistry).to receive(:for_visitor).and_call_original
    allow(TestTrack::Remote::AssignmentRegistry).to receive(:fake_instance_attributes).and_return(assignment_registry)
    allow(TestTrack::Remote::SplitRegistry).to receive(:to_hash).and_return(split_registry)
  end

  it "preserves a passed ID" do
    expect(existing_visitor.id).to eq existing_visitor_id
  end

  it "generates its own UUID otherwise" do
    allow(SecureRandom).to receive(:uuid).and_return("fake uuid")
    expect(new_visitor.id).to eq "fake uuid"
  end

  describe "#assignment_registry" do
    it "doesn't request the registry for a newly-generated visitor" do
      expect(new_visitor.assignment_registry).to eq({})
      expect(TestTrack::Remote::AssignmentRegistry).not_to have_received(:for_visitor)
    end

    it "returns the server-provided assignments for an existing visitor" do
      expect(existing_visitor.assignment_registry).to eq assignment_registry
    end

    it "returns nil if fetching the registry times out" do
      allow(TestTrack::Remote::AssignmentRegistry).to receive(:for_visitor) { raise(Faraday::TimeoutError, "Womp womp") }

      expect(existing_visitor.assignment_registry).to eq nil

      expect(TestTrack::Remote::AssignmentRegistry).to have_received(:for_visitor)
    end
  end

  describe "#vary" do
    let(:blue_block) { -> { '.blue' } }
    let(:red_block) { -> { '.red' } }

    before do
      allow(TestTrack::VariantCalculator).to receive(:new).and_return(double(variant: 'manageable'))
    end

    context "new_visitor" do
      def vary_quagmire_split
        new_visitor.vary(:quagmire) do |v|
          v.when :untenable do
            raise "this branch shouldn't be executed, buddy"
          end
          v.default :manageable do
            "#winning"
          end
        end
      end

      it "asks the VariantCalculator for an assignment" do
        expect(vary_quagmire_split).to eq "#winning"
        expect(TestTrack::VariantCalculator).to have_received(:new).with(visitor: new_visitor, split_name: 'quagmire')
      end

      it "updates #new_assignments with assignment" do
        expect(vary_quagmire_split).to eq "#winning"
        expect(new_visitor.new_assignments['quagmire']).to eq 'manageable'
      end
    end

    context "existing_visitor" do
      def vary_blue_button_split
        existing_visitor.vary :blue_button do |v|
          v.when :true, &blue_block
          v.default :false, &red_block
        end
      end

      def vary_time_split
        existing_visitor.vary :time do |v|
          v.when :clobberin_time do
            "Fantastic Four IV: The Fantasticing"
          end
          v.default :hammertime do
            "can't touch this"
          end
        end
      end

      it "pulls previous assignment from registry" do
        expect(vary_blue_button_split).to eq ".blue"
        expect(TestTrack::VariantCalculator).not_to have_received(:new)

        expect(existing_visitor.new_assignments).not_to have_key('blue_button')
      end

      it "creates new assignment for unimplemented previous assignment" do
        expect(existing_visitor.assignment_registry['time']).to eq 'waits_for_no_man'

        expect(vary_time_split).to eq "can't touch this"
        expect(TestTrack::VariantCalculator).not_to have_received(:new)

        expect(existing_visitor.new_assignments['time']).to eq 'hammertime'
      end

      context "when TestTrack server is unavailable" do
        before do
          allow(TestTrack::Remote::AssignmentRegistry).to receive(:for_visitor) { raise(Faraday::TimeoutError, "woopsie") }
        end

        it "doesn't assign anything" do
          expect(vary_time_split).to eq "can't touch this"
          expect(existing_visitor.new_assignments).to eq({})
          expect(existing_visitor.assignment_registry).to eq nil
        end
      end
    end

    context "structure" do
      it "must be given a block" do
        expect { new_visitor.vary(:blue_button) }.to raise_error("must provide block to `vary` for blue_button")
      end

      it "requires less than two defaults" do
        expect do
          new_visitor.vary(:blue_button) do |v|
            v.when :true, &blue_block
            v.default :false, &red_block
            v.default :false, &red_block
          end
        end.to raise_error("cannot provide more than one `default`")
      end

      it "requires more than zero defaults" do
        expect { new_visitor.vary(:blue_button) { |v| v.when(:true, &blue_block) } }.to raise_error("must provide exactly one `default`")
      end

      it "requires at least one when" do
        expect do
          new_visitor.vary(:blue_button) do |v|
            v.default :true, &red_block
          end
        end.to raise_error("must provide at least one `when`")
      end
    end
  end

  describe "#ab" do
    it "leverages vary to configure the split" do
      allow(new_visitor).to receive(:vary).and_call_original
      new_visitor.ab "quagmire", "manageable"
      expect(new_visitor).to have_received(:vary).with("quagmire").exactly(:once)
    end

    context "with an explicit true_variant" do
      it "returns true when assigned to the true_variant" do
        allow(TestTrack::VariantCalculator).to receive(:new).and_return(double(variant: 'manageable'))
        expect(new_visitor.ab "quagmire", "manageable").to eq true
      end

      it "returns false when not assigned to the true_variant" do
        allow(TestTrack::VariantCalculator).to receive(:new).and_return(double(variant: 'untenable'))
        expect(new_visitor.ab "quagmire", "manageable").to eq false
      end
    end

    context "with an implicit true_variant" do
      it "returns true when variant is true" do
        allow(TestTrack::VariantCalculator).to receive(:new).and_return(double(variant: 'true'))
        expect(new_visitor.ab "blue_button").to eq true
      end

      it "returns false when variant is false" do
        allow(TestTrack::VariantCalculator).to receive(:new).and_return(double(variant: 'false'))
        expect(new_visitor.ab "blue_button").to eq false
      end

      it "returns false when split variants are not true and false" do
        expect(new_visitor.ab "time").to eq false
      end
    end
  end

  describe "#split_registry" do
    it "memoizes the global SplitRegistry hash" do
      2.times { existing_visitor.split_registry }
      expect(TestTrack::Remote::SplitRegistry).to have_received(:to_hash).exactly(:once)
    end
  end
end
