require 'rails_helper'

RSpec.describe TestTrack::SessionIdentityCollection do
  let(:controller_class) do
    Class.new(ApplicationController) do
      include TestTrack::Controller

      private # make current_clown private to better simulate real world scenario

      def current_clown; end
    end
  end

  let(:controller) { controller_class.new }
  let(:clown) { Clown.new(id: 1234) }
  let(:other_clown) { Clown.new(id: 9876) }
  let(:magician) { Magician.new(id: 1234) }

  subject { described_class.new(controller) }

  describe "#<<" do
    it "adds the identity to its collection" do
      subject << clown
      expect(subject.include?(clown)).to eq true
    end

    it "keeps the latest added identity for a given identifier type" do
      subject << clown
      subject << other_clown
      subject << magician
      expect(subject.include?(clown)).to eq false
      expect(subject.include?(other_clown)).to eq true
      expect(subject.include?(magician)).to eq true
    end
  end

  describe "#include?" do
    context "when the controller has an authenticated resource for the identity type" do
      before do
        allow(controller).to receive(:current_clown).and_return(clown)
      end

      it "return true" do
        expect(subject.include?(clown)).to eq true
      end

      context "when another identity of the same type is added" do
        before do
          subject << other_clown
        end

        it "returns true for only the most recently added identity" do
          expect(subject.include?(clown)).to eq false
          expect(subject.include?(other_clown)).to eq true
        end
      end

      context "when an identity of a different type is added" do
        before do
          subject << magician
        end

        it "returns true when " do
          expect(subject.include?(clown)).to eq true
          expect(subject.include?(magician)).to eq true
        end
      end
    end

    context "when no identity has been added" do
      it "returns false" do
        expect(subject.include?(clown)).to eq false
      end
    end
  end
end
