require 'rails_helper'

RSpec.describe TestTrack::OfflineSession do
  describe ".with_visitor_for" do
    let(:remote_visitor) do
      TestTrack::Remote::IdentifierVisitor.new(
        id: "remote_visitor_id",
        assignment_registry: { "foo" => "bar" },
        unsynced_splits: []
      )
    end
    let(:visitor) { instance_double(TestTrack::Visitor, id: "remote_visitor_id", unsynced_assignments: {}) }
    let(:visitor_dsl) { instance_double(TestTrack::VisitorDSL) }

    before do
      allow(TestTrack::Remote::IdentifierVisitor).to receive(:from_identifier).and_return(remote_visitor)
      allow(TestTrack::Visitor).to receive(:new).and_return(visitor)
      allow(TestTrack::VisitorDSL).to receive(:new).and_return(visitor_dsl)
      allow(Delayed::Job).to receive(:enqueue).and_return(true)
    end

    it "blows up when a block is not provided" do
      expect { described_class.with_visitor_for("clown_id", "1234") }
        .to raise_error("must provide block to `with_visitor_for`")
    end

    it "gets the remote visitor via the identifier info" do
      described_class.with_visitor_for("clown_id", 1234) {}
      expect(TestTrack::Remote::IdentifierVisitor).to have_received(:from_identifier).with("clown_id", 1234)
    end

    it "creates a visitor with the properties of the remote visitor" do
      described_class.with_visitor_for("clown_id", 1234) {}
      expect(TestTrack::Visitor).to have_received(:new).with(
        id: "remote_visitor_id",
        assignment_registry: { "foo" => "bar" },
        unsynced_splits: []
      )
    end

    it "instantiates a session with the identifier_type and identifier_value" do
      allow(described_class).to receive(:new).and_call_original

      described_class.with_visitor_for("clown_id", 1234) {}

      expect(described_class).to have_received(:new).with("clown_id", 1234)
    end

    it "yields a VisitorDSL" do
      described_class.with_visitor_for("clown_id", 1234) do |v|
        expect(v).to eq(visitor_dsl)
      end

      expect(TestTrack::VisitorDSL).to have_received(:new).with(visitor)
    end

    context "notify assignments" do
      before do
        allow(TestTrack::NotifyAssignmentsJob).to receive(:new).and_call_original
      end

      it "enqueues an assignment notification job if there are unsynced assignments" do
        allow(visitor).to receive(:unsynced_assignments).and_return('has_button' => 'false')

        expect(TestTrack::NotifyAssignmentsJob).to receive(:new).with(
          mixpanel_distinct_id: "remote_visitor_id",
          visitor_id: "remote_visitor_id",
          assignments: { 'has_button' => 'false' }
        )

        described_class.with_visitor_for("clown_id", 1234) {}

        expect(Delayed::Job).to have_received(:enqueue).with(an_instance_of(TestTrack::NotifyAssignmentsJob))
      end

      it "does not enqueue a new assignment notification job if there are no unsynced assignments" do
        allow(visitor).to receive(:unsynced_assignments).and_return({})

        described_class.with_visitor_for("clown_id", 1234) {}

        expect(TestTrack::NotifyAssignmentsJob).not_to have_received(:new)
        expect(Delayed::Job).not_to have_received(:enqueue)
      end
    end
  end
end
