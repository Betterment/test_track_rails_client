require 'rails_helper'

RSpec.describe TestTrack::WebSessionVisitorRepository do
  let(:my_clown) { double(test_track_identifier_type: "clown_id", test_track_identifier_value: "my_clown_id") }
  let(:your_clown) { double(test_track_identifier_type: "clown_id", test_track_identifier_value: "your_clown_id") }
  let(:unauthenticated_visitor_id) { "12345abc" }

  subject do
    described_class.new(
      current_identity: current_identity,
      unauthenticated_visitor_id: unauthenticated_visitor_id
    )
  end

  describe "#current" do
    context "with a current_identity" do
      let(:current_identity) { my_clown }
      it "returns a LazyVisitorByIdentity" do
        expect(subject.current).to be_a(TestTrack::LazyVisitorByIdentity)
      end
    end

    context "without a current_identity" do
      let(:current_identity) { nil }
      it "returns a visitor seeded from the unauthenticated visitor ID" do
        subject.current.tap do |result|
          expect(result).to be_a(TestTrack::Visitor)
          expect(result.id).to eq "12345abc"
        end
      end
    end
  end

  describe "#for_identity" do
    let(:current_identity) { nil }

    it "returns the same instance for the same identity" do
      expect(subject.for_identity(my_clown)).to equal(subject.for_identity(my_clown))
    end

    it "returns a different one for a different entity" do
      expect(subject.for_identity(my_clown)).not_to equal(subject.for_identity(your_clown))
    end
  end

  describe "#forget_unauthenticated!" do
    let(:current_identity) { nil }

    it "changes visitor id" do
      expect(subject.current.id).to eq "12345abc"
      subject.forget_unauthenticated!
      expect(subject.current.id).not_to eq "12345abc"
    end
  end

  describe "#authenticate!" do
    context "with an identity" do
      let(:current_identity) { your_clown }

      it "changes its idea of current_identity" do
        expect(subject.current_identity).to eq your_clown
        subject.authenticate!(my_clown)
        expect(subject.current_identity).to eq my_clown
      end

      it "promotes unauthenticated_visitor to current visitor" do
        expect(subject.current.id).not_to eq("12345abc")
        subject.authenticate!(my_clown)
        expect(subject.current.id).to eq("12345abc")
      end
    end

    context "without an identity" do
      let(:current_identity) { nil }

      it "links the current unauthenticated visitor to the provided identity" do
        allow(subject.current).to receive(:link_identity!).and_call_original
        subject.authenticate!(my_clown)
        expect(subject.current).to have_received(:link_identity!).with(my_clown)
      end
    end
  end
end
