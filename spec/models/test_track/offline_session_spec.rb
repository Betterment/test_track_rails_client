require 'rails_helper'

RSpec.describe TestTrack::OfflineSession do
  describe ".with_visitor_for" do
    let(:remote_visitor) { TestTrack::Remote::IdentifierVisitor.new(id: "remote_visitor_id", assignment_registry: { "foo" => "bar" }) }
    let(:visitor) { instance_double(TestTrack::Visitor, id: "remote_visitor_id", new_assignments: {}) }
    let(:visitor_dsl) { instance_double(TestTrack::VisitorDSL) }
    let(:notify_new_assignments_job) { instance_double(TestTrack::NotifyNewAssignmentsJob, perform: true) }

    subject { described_class.with_visitor_for("clown_id", 1234) {} }

    before do
      allow(TestTrack::Remote::IdentifierVisitor).to receive(:from_identifier).and_return(remote_visitor)
      allow(TestTrack::Visitor).to receive(:new).and_return(visitor)
      allow(described_class).to receive(:new).and_call_original
      allow(TestTrack::VisitorDSL).to receive(:new).and_return(visitor_dsl)
      allow(TestTrack::NotifyNewAssignmentsJob).to receive(:new).and_return(notify_new_assignments_job)
      allow(Delayed::Job).to receive(:enqueue).and_return(true)
    end

    it "blows up when a block is not provided" do
      expect { described_class.with_visitor_for("clown_id", "1234") }
        .to raise_error("must provide block to `with_visitor_for`")
    end

    it "gets the remote visitor via the identifier info" do
      subject
      expect(TestTrack::Remote::IdentifierVisitor).to have_received(:from_identifier).with("clown_id", 1234)
    end

    it "creates a visitor with the properties of the remote visitor" do
      subject
      expect(TestTrack::Visitor).to have_received(:new).with(id: "remote_visitor_id", assignment_registry: { "foo" => "bar" })
    end

    it "instantiates a session with the visitor" do
      subject
      expect(described_class).to have_received(:new).with(visitor)
    end

    it "yields a VisitorDSL" do
      described_class.with_visitor_for("clown_id", 1234) do |v|
        expect(v).to eq(visitor_dsl)
      end

      expect(TestTrack::VisitorDSL).to have_received(:new).with(visitor)
    end

    it "enqueues a new assignment notification job if there are new assignments" do
      allow(visitor).to receive(:new_assignments).and_return('has_button' => 'false')

      subject

      expect(TestTrack::NotifyNewAssignmentsJob).to have_received(:new).with(
        mixpanel_distinct_id: "remote_visitor_id",
        visitor_id: "remote_visitor_id",
        new_assignments: { 'has_button' => 'false' }
      )
      expect(Delayed::Job).to have_received(:enqueue).with(notify_new_assignments_job)
    end

    it "does not enqueue a new assignment notification job if there are no new assignments" do
      allow(visitor).to receive(:new_assignments).and_return({})

      subject

      expect(TestTrack::NotifyNewAssignmentsJob).not_to have_received(:new)
      expect(Delayed::Job).not_to have_received(:enqueue)
    end
  end
end
