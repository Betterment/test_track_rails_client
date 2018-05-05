require 'rails_helper'

RSpec.describe TestTrack::LazyVisitorByIdentity do
  let(:identity) { double(test_track_identifier_type: "clown_id", test_track_identifier_value: "123") }
  subject { described_class.new(identity) }
  describe "#loaded? and #id_loaded?" do
    def expect_them_to_be(expected_result)
      expect(subject.loaded?).to eq expected_result
      expect(subject.id_loaded?).to eq expected_result
    end

    it "returns false if no method on underlying has been hit" do
      expect_them_to_be false
    end

    it "loads even if a completely missing method is called" do
      expect { subject.nonexistent_method }.to raise_error(NoMethodError)
      expect_them_to_be true
    end

    it "is loaded if id is called" do
      subject.id

      expect_them_to_be true
    end
  end

  describe "#respond_to?" do
    it "returns true if underlying responds to it" do
      expect(subject.respond_to?(:id)).to eq true
    end

    it "returns true if we actually respond to it" do
      expect(subject.respond_to?(:id_loaded?)).to eq true
    end

    it "returns false if random" do
      expect(subject.respond_to?(:fooblitz)).to eq false
    end
  end
end
