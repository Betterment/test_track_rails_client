require 'rails_helper'

RSpec.describe TestTrackRails::Visitor do

  let(:new_visitor) { described_class.new }
  let(:existing_visitor) { described_class.new(id: existing_visitor_id) }
  let(:existing_visitor_id) { "00000000-0000-0000-0000-000000000000" }
  let(:assignment_registry) { { 'blue_button' => 'true' } }
  let(:split_registry) do
    {
      'blue_button' => {
        'false' => 50,
        'true' => 50
      },
      'quagmire' => {
        'untenable' => 50,
        'manageable' => 50
      }
    }
  end

  before do
    allow(TestTrackRails::AssignmentRegistry).to receive(:for_visitor).and_call_original
    allow(TestTrackRails::AssignmentRegistry).to receive(:fake_instance_attributes).and_return(assignment_registry)
    allow(TestTrackRails::SplitRegistry).to receive(:to_hash).and_return(split_registry)
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
      expect(TestTrackRails::AssignmentRegistry).not_to have_received(:for_visitor)
    end

    it "returns the server-provided assignments for an existing visitor" do
      expect(existing_visitor.assignment_registry).to eq assignment_registry
    end
  end

  describe "#new_assignments" do
    it "doesn't include a server-provided assignment, even if requested" do
      expect(existing_visitor.assignment_for('blue_button')).to eq(true)

      expect(existing_visitor.new_assignments).not_to have_key('blue_button')
    end
  end

  describe "#assignment_for" do
    before do
      allow(TestTrackRails::VariantCalculator).to receive(:new).and_return(double(variant: 'untenable'))
    end

    it "returns an existing assignment without generating" do
      expect(existing_visitor.assignment_for('blue_button')).to eq(true)

      expect(TestTrackRails::VariantCalculator).not_to have_received(:new)
    end

    it "assigns a new split via VariantCalculator" do

      expect(existing_visitor.assignment_for('quagmire')).to eq('untenable')

      expect(TestTrackRails::VariantCalculator).to have_received(:new).with(visitor: existing_visitor, split_name: 'quagmire')
    end

    it "adds new assignments to new_assignments" do
      expect(existing_visitor.assignment_for('quagmire')).to eq('untenable')

      expect(existing_visitor.new_assignments['quagmire']).to eq 'untenable'
    end

    it "adds new assigments to assignment_registry" do
      expect(existing_visitor.assignment_for('quagmire')).to eq('untenable')

      expect(existing_visitor.assignment_registry['quagmire']).to eq 'untenable'
    end
  end

  describe "#split_registry" do
    it "memoizes the global SplitRegistry hash" do
      2.times { existing_visitor.split_registry }
      expect(TestTrackRails::SplitRegistry).to have_received(:to_hash).exactly(:once)
    end
  end
end
