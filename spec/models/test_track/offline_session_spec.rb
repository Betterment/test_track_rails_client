require 'rails_helper'

RSpec.describe TestTrack::OfflineSession do
  let(:remote_visitor) do
    TestTrack::Remote::Visitor.new(
      id: "remote_visitor_id",
      assignments: [
        { split_name: "foo", variant: "bar", unsynced: false }
      ]
    )
  end

  describe ".with_visitor_for" do
    before do
      allow(TestTrack::Remote::Visitor).to receive(:from_identifier).and_return(remote_visitor)
    end

    it "blows up when a block is not provided" do
      expect { described_class.with_visitor_for("clown_id", 1234) }
        .to raise_error("must provide block to `with_visitor_for`")
    end

    it "gets the remote visitor via the identifier info" do
      described_class.with_visitor_for("clown_id", 1234) {}
      expect(TestTrack::Remote::Visitor).to have_received(:from_identifier).with("clown_id", 1234)
    end

    it "creates a visitor with the properties of the remote visitor" do
      allow(TestTrack::Visitor).to receive(:new).and_call_original

      described_class.with_visitor_for("clown_id", 1234) {}

      expect(TestTrack::Visitor).to have_received(:new) do |args|
        expect(args[:id]).to eq("remote_visitor_id")
        args[:assignments].first.tap do |assignment|
          expect(assignment.visitor_id).to eq("remote_visitor_id")
          expect(assignment.split_name).to eq("foo")
          expect(assignment.variant).to eq("bar")
          expect(assignment).to respond_to(:context)
          expect(assignment.unsynced?).to eq false
        end
      end
    end

    it "instantiates a session with the remote_visitor" do
      allow(described_class).to receive(:new).and_call_original

      described_class.with_visitor_for("clown_id", 1234) {}

      expect(described_class).to have_received(:new).with(remote_visitor)
    end

    it "yields a VisitorDSL" do
      allow(TestTrack::VisitorDSL).to receive(:new).and_call_original

      described_class.with_visitor_for("clown_id", 1234) do |v|
        expect(v).to be_an_instance_of(TestTrack::VisitorDSL)
      end

      expect(TestTrack::VisitorDSL).to have_received(:new).with(an_instance_of(TestTrack::Visitor))
    end

    context "notify unsynced assignments" do
      let(:unsynced_assignments_notifier) { instance_double(TestTrack::UnsyncedAssignmentsNotifier, notify: true) }

      before do
        allow(TestTrack::Remote::SplitRegistry).to receive(:to_hash).and_return("has_button" => { "false" => 0, "true" => 100 })
        allow(TestTrack::UnsyncedAssignmentsNotifier).to receive(:new).and_return(unsynced_assignments_notifier)
      end

      it "notifies unsynced assignments" do
        described_class.with_visitor_for("clown_id", 1234) do |visitor|
          visitor.ab :has_button, context: :spec
        end

        expect(TestTrack::UnsyncedAssignmentsNotifier).to have_received(:new) do |args|
          expect(args[:visitor_id]).to eq('remote_visitor_id')
          args[:assignments].first.tap do |assignment|
            expect(assignment.split_name).to eq('has_button')
            expect(assignment.variant).to eq('true')
          end
        end

        expect(unsynced_assignments_notifier).to have_received(:notify)
      end

      it "does not notify unsynced assignments if there are no unsynced assignments" do
        described_class.with_visitor_for("clown_id", 1234) {}

        expect(TestTrack::UnsyncedAssignmentsNotifier).not_to have_received(:new)
      end
    end
  end

  describe '.with_visitor_id' do
    before do
      allow(TestTrack::Remote::Visitor).to receive(:find).and_return(remote_visitor)
    end

    it "blows up when a block is not provided" do
      expect { described_class.with_visitor_id(1234) }
        .to raise_error("must provide block to `with_visitor_id`")
    end

    it "gets the remote visitor via the visitor_id" do
      described_class.with_visitor_id(1234) {}
      expect(TestTrack::Remote::Visitor).to have_received(:find).with(1234)
    end

    it "creates a visitor with the properties of the remote visitor" do
      allow(TestTrack::Visitor).to receive(:new).and_call_original

      described_class.with_visitor_id(1234) {}

      expect(TestTrack::Visitor).to have_received(:new) do |args|
        expect(args[:id]).to eq("remote_visitor_id")
        args[:assignments].first.tap do |assignment|
          expect(assignment.split_name).to eq("foo")
          expect(assignment.variant).to eq("bar")
        end
      end
    end

    it "instantiates a session with the remote_visitor" do
      allow(described_class).to receive(:new).and_call_original

      described_class.with_visitor_id(1234) {}

      expect(described_class).to have_received(:new).with(remote_visitor)
    end

    it "yields a VisitorDSL" do
      allow(TestTrack::VisitorDSL).to receive(:new).and_call_original

      described_class.with_visitor_id(1234) do |v|
        expect(v).to be_an_instance_of(TestTrack::VisitorDSL)
      end

      expect(TestTrack::VisitorDSL).to have_received(:new).with(an_instance_of(TestTrack::Visitor))
    end

    context "notify unsynced assignments" do
      let(:unsynced_assignments_notifier) { instance_double(TestTrack::UnsyncedAssignmentsNotifier, notify: true) }

      before do
        allow(TestTrack::Remote::SplitRegistry).to receive(:to_hash).and_return("has_button" => { "false" => 0, "true" => 100 })
        allow(TestTrack::UnsyncedAssignmentsNotifier).to receive(:new).and_return(unsynced_assignments_notifier)
      end

      it "notifies unsynced assignments" do
        described_class.with_visitor_id(1234) do |visitor|
          visitor.ab :has_button, context: :spec
        end

        expect(TestTrack::UnsyncedAssignmentsNotifier).to have_received(:new) do |args|
          expect(args[:visitor_id]).to eq('remote_visitor_id')
          args[:assignments].first.tap do |assignment|
            expect(assignment.split_name).to eq('has_button')
            expect(assignment.variant).to eq('true')
          end
        end

        expect(unsynced_assignments_notifier).to have_received(:notify)
      end

      it "does not notify unsynced assignments if there are no unsynced assignments" do
        described_class.with_visitor_id(1234) {}

        expect(TestTrack::UnsyncedAssignmentsNotifier).not_to have_received(:new)
      end
    end
  end
end
