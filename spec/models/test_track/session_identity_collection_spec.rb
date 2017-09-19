require 'rails_helper'

RSpec.describe TestTrack::SessionIdentityCollection do
  let(:controller_class) do
    Class.new(ApplicationController) do
      include TestTrack::Controller

      private # make current_clown private to better simulate real world scenario

      def current_clown
      end
    end
  end

  let(:controller) { controller_class.new }
  let(:identity) { Clown.new(id: 1234) }
  let(:other_identity) { Clown.new(id: 9876) }

  subject { described_class.new(controller) }

  describe "#<<" do
    it "adds the identity to its collection" do
      subject << identity
      expect(subject.find_by_identifier_type(identity)).to eq identity
    end

    it "keeps the latest added identity for a given identifier type" do
      subject << identity
      subject << other_identity
      expect(subject.find_by_identifier_type(identity)).to eq other_identity
    end
  end

  describe "#find_by_identifier_type" do
    context "when the controller has an authenticated resource for the identity type" do
      before do
        allow(controller).to receive(:current_clown).and_return(identity)
      end

      it "return the controller's resource" do
        expect(subject.find_by_identifier_type(identity)).to eq identity
      end

      context "when a previously added identity matches the given type" do
        it "returns the previously added identity" do
          subject << other_identity
          expect(subject.find_by_identifier_type(identity)).to eq other_identity
        end
      end
    end

    context "when no identity has been added" do
      it "returns nil" do
        expect(subject.find_by_identifier_type(identity)).to eq nil
      end
    end
  end
end
