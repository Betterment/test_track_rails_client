require 'rails_helper'

module TestTrack
  RSpec.describe ConfigUpdater do
    describe "#split" do
      it "updates split_config" do
        allow(SplitConfig).to receive(:create!).and_call_original
        expect(subject.split(:name, foo: 20, bar: 80)).to be_truthy
        expect(SplitConfig).to have_received(:create!).with(name: :name, weighting_registry: { foo: 20, bar: 80 })
      end
    end

    describe "#identifier_type" do
      it "updates identifier_type" do
        allow(IdentifierType).to receive(:create!).and_call_original
        expect(subject.identifier_type(:my_id)).to be_truthy
        expect(IdentifierType).to have_received(:create!).with(name: :my_id)
      end
    end
  end
end
