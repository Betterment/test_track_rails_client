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

    before do
      allow(TestTrack::Remote::IdentifierVisitor).to receive(:from_identifier).and_return(remote_visitor)
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
      allow(TestTrack::Visitor).to receive(:new).and_call_original
      expect(TestTrack::Visitor).to receive(:new).with(
        id: "remote_visitor_id",
        assignment_registry: { "foo" => "bar" },
        unsynced_splits: []
      )

      described_class.with_visitor_for("clown_id", 1234) {}
    end

    it "instantiates a session with the identifier_type and identifier_value" do
      allow(described_class).to receive(:new).and_call_original

      described_class.with_visitor_for("clown_id", 1234) {}

      expect(described_class).to have_received(:new).with("clown_id", 1234)
    end

    it "yields a VisitorDSL" do
      allow(TestTrack::VisitorDSL).to receive(:new).and_call_original
      expect(TestTrack::VisitorDSL).to receive(:new).with(an_instance_of(TestTrack::Visitor))

      described_class.with_visitor_for("clown_id", 1234) do |v|
        expect(v).to be_an_instance_of(TestTrack::VisitorDSL)
      end
    end

    context "notify unsynced assignments" do
      let(:unsynced_assignments_notifier) { instance_double(TestTrack::UnsyncedAssignmentsNotifier, notify: true) }

      before do
        allow(TestTrack::Remote::SplitRegistry).to receive(:to_hash).and_return("has_button" => { "false" => 0, "true" => 100 })
        allow(TestTrack::UnsyncedAssignmentsNotifier).to receive(:new).and_return(unsynced_assignments_notifier)
      end

      it "notifies unsynced assignments" do
        described_class.with_visitor_for("clown_id", 1234) do |visitor|
          visitor.ab :has_button
        end

        expect(TestTrack::UnsyncedAssignmentsNotifier).to have_received(:new).with(
          mixpanel_distinct_id: "remote_visitor_id",
          visitor_id: "remote_visitor_id",
          assignments: { 'has_button' => 'true' }
        )

        expect(unsynced_assignments_notifier).to have_received(:notify)
      end

      it "does not notify unsynced assignments if there are no unsynced assignments" do
        described_class.with_visitor_for("clown_id", 1234) {}

        expect(TestTrack::UnsyncedAssignmentsNotifier).not_to have_received(:new)
      end
    end
  end
end
