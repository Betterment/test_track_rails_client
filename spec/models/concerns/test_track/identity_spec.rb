require 'rails_helper'

RSpec.describe TestTrack::Identity do
  Clown = Class.new do
    include TestTrack::Identity

    test_track_identifier "clown_id", :id

    def id
      1234
    end
  end

  let(:test_track_controller_class) do
    Class.new(ApplicationController) { include TestTrack::Controller }
  end

  let(:test_track_controller) { test_track_controller_class.new }

  subject { Clown.new }

  describe ".test_track_identifier" do
    let(:unsynced_assignments_notifier) { instance_double(TestTrack::UnsyncedAssignmentsNotifier, notify: true) }

    before do
      allow(TestTrack::OfflineSession).to receive(:with_visitor_for).and_call_original
      allow(TestTrack::VisitorDSL).to receive(:new).and_call_original
      allow(TestTrack::UnsyncedAssignmentsNotifier).to receive(:new).and_return(unsynced_assignments_notifier)
      allow(TestTrack::Remote::SplitRegistry).to receive(:to_hash).and_return(
        "blue_button" => { "true" => 0, "false" => 100 },
        "side_dish" => { "soup" => 0, "salad" => 100 }
      )
    end

    context "#test_track_ab" do
      context "in a web request" do
        let(:visitor) { TestTrack::Visitor.new }
        let(:visitor_dsl) { TestTrack::VisitorDSL.new(visitor) }

        before do
          allow(RequestStore).to receive(:exist?).and_return(true)
          allow(RequestStore).to receive(:[]).with(:test_track_controller).and_return(test_track_controller)
          allow(test_track_controller).to receive(:test_track_visitor).and_return(visitor_dsl)
          allow(visitor).to receive(:ab).and_call_original
        end

        it "returns the correct value" do
          expect(subject.test_track_ab(:blue_button)).to be false
        end

        it "forwards all arguments to the visitor correctly" do
          subject.test_track_ab(:side_dish, "soup")
          expect(visitor).to have_received(:ab).with(:side_dish, "soup")
        end

        it "does not create an offline session" do
          subject.test_track_ab(:blue_button)
          expect(TestTrack::OfflineSession).not_to have_received(:with_visitor_for)
        end

        it "does not send notifications inline" do
          subject.test_track_ab(:blue_button)
          expect(TestTrack::UnsyncedAssignmentsNotifier).not_to have_received(:new)
        end

        it "appends the assignment to the visitor's unsynced assignments" do
          subject.test_track_ab(:blue_button)
          expect(visitor.unsynced_assignments).to eq("blue_button" => "false")
        end

        context "controller has a #current_* method" do
          before do
            test_track_controller.class_eval do
              def current_clown
              end
            end
          end

          it "uses an online session when the #current_* equals the subject" do
            allow(test_track_controller).to receive(:current_clown).and_return(subject)

            subject.test_track_ab(:blue_button)
            expect(TestTrack::OfflineSession).not_to have_received(:with_visitor_for)
          end

          it "uses an offline session when the #current_* does not equal the subject" do
            allow(test_track_controller).to receive(:current_clown).and_return(Clown.new)

            subject.test_track_ab(:blue_button)
            expect(TestTrack::OfflineSession).to have_received(:with_visitor_for)
          end
        end
      end

      context "not in a web request" do
        let(:visitor) { TestTrack::Visitor.new(id: "fake_visitor_id") }

        before do
          allow(TestTrack::Visitor).to receive(:new).and_return(visitor)
          allow(visitor).to receive(:ab).and_call_original
        end

        it "returns the correct value" do
          expect(subject.test_track_ab(:blue_button)).to be false
        end

        it "forwards all arguments to the visitor correctly" do
          subject.test_track_ab(:side_dish, "soup")
          expect(visitor).to have_received(:ab).with(:side_dish, "soup")
        end

        it "creates an offline session" do
          subject.test_track_ab :blue_button
          expect(TestTrack::OfflineSession).to have_received(:with_visitor_for).with("clown_id", 1234)
        end

        it "sends notifications inline" do
          subject.test_track_ab :blue_button
          expect(TestTrack::UnsyncedAssignmentsNotifier).to have_received(:new).with(
            mixpanel_distinct_id: "fake_visitor_id",
            visitor_id: "fake_visitor_id",
            assignments: { "blue_button" => "false" }
          )
        end
      end
    end

    context "#test_track_vary" do
      def vary_side_dish
        subject.test_track_vary(:side_dish) do |v|
          v.when(:soup) { "soups on" }
          v.default(:salad) { "salad please" }
        end
      end

      context "in a web request" do
        let(:visitor) { TestTrack::Visitor.new }
        let(:visitor_dsl) { TestTrack::VisitorDSL.new(visitor) }

        before do
          allow(RequestStore).to receive(:exist?).and_return(true)
          allow(RequestStore).to receive(:[]).with(:test_track_controller).and_return(test_track_controller)
          allow(test_track_controller).to receive(:test_track_visitor).and_return(visitor_dsl)
        end

        it "returns the correct value" do
          expect(vary_side_dish).to eq "salad please"
        end

        it "does not create an offline session" do
          vary_side_dish
          expect(TestTrack::OfflineSession).not_to have_received(:with_visitor_for)
        end

        it "does not send notifications inline" do
          vary_side_dish
          expect(TestTrack::UnsyncedAssignmentsNotifier).not_to have_received(:new)
        end

        it "appends the assignment to the visitor's unsynced assignments" do
          vary_side_dish
          expect(visitor.unsynced_assignments).to eq("side_dish" => "salad")
        end

        context "controller has a #current_* method" do
          before do
            test_track_controller.class_eval do
              def current_clown
              end
            end
          end

          it "uses an online session when the #current_* equals the subject" do
            allow(test_track_controller).to receive(:current_clown).and_return(subject)

            vary_side_dish
            expect(TestTrack::OfflineSession).not_to have_received(:with_visitor_for)
          end

          it "uses an offline session when the #current_* does not equal the subject" do
            allow(test_track_controller).to receive(:current_clown).and_return(Clown.new)

            vary_side_dish
            expect(TestTrack::OfflineSession).to have_received(:with_visitor_for)
          end
        end
      end

      context "not in a web request" do
        it "returns the correct value" do
          expect(vary_side_dish).to eq "salad please"
        end

        it "creates an offline session" do
          vary_side_dish
          expect(TestTrack::OfflineSession).to have_received(:with_visitor_for).with("clown_id", 1234)
        end

        it "sends notifications inline" do
          vary_side_dish
          expect(TestTrack::UnsyncedAssignmentsNotifier).to have_received(:new).with(
            mixpanel_distinct_id: "fake_visitor_id",
            visitor_id: "fake_visitor_id",
            assignments: { "side_dish" => "salad" }
          )
        end
      end
    end
  end
end
