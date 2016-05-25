require 'rails_helper'

RSpec.describe TestTrack::Session do
  let(:controller) { instance_double(ApplicationController, cookies: cookies, request: request) }
  let(:cookies) { { tt_visitor_id: "fake_visitor_id", mp_fakefakefake_mixpanel: mixpanel_cookie }.with_indifferent_access }
  let(:mixpanel_cookie) { { distinct_id: "fake_distinct_id", OtherProperty: "bar" }.to_json }
  let(:request) { double(:request, host: "www.foo.com", ssl?: true) }
  let(:unsynced_assignments_notifier) { instance_double(TestTrack::UnsyncedAssignmentsNotifier, notify: true) }

  subject { described_class.new(controller) }

  before do
    allow(TestTrack::UnsyncedAssignmentsNotifier).to receive(:new).and_return(unsynced_assignments_notifier)
    allow(Thread).to receive(:new).and_call_original
    allow(TestTrack::CreateAliasJob).to receive(:new).and_call_original
    ENV['MIXPANEL_TOKEN'] = 'fakefakefake'
  end

  describe "#manage" do
    context "visitor" do
      it "sets a visitor ID cookie" do
        subject.manage {}
        expect(cookies['tt_visitor_id'][:value]).to eq "fake_visitor_id"
      end

      context "with no visitor cookie" do
        let(:cookies) { { mp_fakefakefake_mixpanel: mixpanel_cookie }.with_indifferent_access }

        it "returns a new visitor id" do
          subject.manage {}
          expect(cookies['tt_visitor_id'][:value]).to match(/\A[a-z0-9\-]{36}\z/)
        end
      end
    end

    context "log_in!" do
      before do
        real_visitor = instance_double(TestTrack::Visitor, id: "real_visitor_id", assignment_registry: {})
        identifier = instance_double(TestTrack::Remote::Identifier, visitor: real_visitor)
        allow(TestTrack::Remote::Identifier).to receive(:create!).and_return(identifier)
      end

      it "provides the current visitor id when requesting an identifier" do
        subject.manage do
          subject.log_in!("identifier_type", "value")

          expect(TestTrack::Remote::Identifier).to have_received(:create!).with(
            identifier_type: "identifier_type",
            visitor_id: "fake_visitor_id",
            value: "value"
          )
        end
      end

      it "sets correct tt_visitor_id" do
        subject.manage do
          subject.log_in!("identifier_type", "value")
        end
        expect(cookies['tt_visitor_id'][:value]).to eq "real_visitor_id"
      end

      it "changes the distinct_id in the mixpanel cookie" do
        subject.manage do
          subject.log_in!("identifier_type", "value")
        end
        expect(cookies['mp_fakefakefake_mixpanel'][:value]).to eq({ distinct_id: "real_visitor_id", OtherProperty: "bar" }.to_json)
      end

      context "forget current visitor" do
        it "creates a temporary visitor when creating the identifier" do
          subject.manage do
            subject.log_in!("identifier_type", "value", forget_current_visitor: true)
          end

          expect(TestTrack::Remote::Identifier).to have_received(:create!).with(
            identifier_type: "identifier_type",
            visitor_id: /\A[a-f0-9\-]{36}\z/,
            value: "value"
          )
        end
      end
    end

    context "mixpanel" do
      it "resets the mixpanel cookie to the same value if already there" do
        subject.manage {}
        expect(cookies['mp_fakefakefake_mixpanel'][:value]).to eq mixpanel_cookie
      end

      context "without mixpanel cookie" do
        let(:cookies) { { tt_visitor_id: "fake_visitor_id" }.with_indifferent_access }

        it "sets the mixpanel cookie's distinct_id to the visitor_id" do
          subject.manage {}
          expect(cookies['mp_fakefakefake_mixpanel'][:value]).to eq({ distinct_id: 'fake_visitor_id' }.to_json)
        end
      end

      context "with malformed mixpanel cookie" do
        let(:cookies) { { tt_visitor_id: "fake_visitor_id", mp_fakefakefake_mixpanel: malformed_mixpanel_cookie }.with_indifferent_access }
        let(:malformed_mixpanel_cookie) do
          URI.escape("{\"distinct_id\": \"fake_distinct_id\", \"referrer\":\"http://bad.com/?q=\"bad\"\"}")
        end

        it "sets the mixpanel cookie's distinct_id to the visitor_id" do
          subject.manage {}
          expect(cookies['mp_fakefakefake_mixpanel'][:value]).to eq({ distinct_id: 'fake_visitor_id' }.to_json)
        end

        it "logs an error" do
          allow(Rails.logger).to receive(:error).and_call_original
          subject.manage {}
          expect(Rails.logger).to have_received(:error).with(
            "malformed mixpanel JSON from cookie {\"distinct_id\": \"fake_distinct_id\", \"referrer\":\"http://bad.com/?q=\"bad\"\"}"
          )
        end
      end
    end

    context "cookies" do
      it "sets secure cookies if the request is ssl" do
        allow(request).to receive(:ssl?).and_return(true)
        subject.manage {}
        expect(cookies['tt_visitor_id'][:secure]).to eq true
      end

      it "sets insecure cookies if the request isn't ssl" do
        allow(request).to receive(:ssl?).and_return(false)
        subject.manage {}
        expect(cookies['tt_visitor_id'][:secure]).to eq false
      end

      it "uses a wildcard domain" do
        allow(request).to receive(:host).and_return("foo.bar.baz.boom.com")
        subject.manage {}
        expect(cookies['tt_visitor_id'][:domain]).to eq ".boom.com"
      end

      it "doesn't munge an IPv4 hostname" do
        allow(request).to receive(:host).and_return("127.0.0.1")
        subject.manage {}
        expect(cookies['tt_visitor_id'][:domain]).to eq "127.0.0.1"
      end

      it "doesn't munge an IPv6 hostname" do
        allow(request).to receive(:host).and_return("::1")
        subject.manage {}
        expect(cookies['tt_visitor_id'][:domain]).to eq "::1"
      end

      it "doesn't set httponly cookies" do
        subject.manage {}
        expect(cookies['tt_visitor_id'][:httponly]).to eq false
      end

      it "expires in a year" do
        Timecop.freeze(Time.zone.parse('2011-01-01')) do
          subject.manage {}
        end
        expect(cookies['tt_visitor_id'][:expires]).to eq Time.zone.parse('2012-01-01')
      end
    end

    context "assignments notifications with threading disabled" do
      let(:remote_visitor_attributes) do
        {
          id: "fake_visitor_id",
          assignment_registry: { 'switched_split' => 'not_what_i_thought' },
          unsynced_splits: %w(switched_split)
        }
      end

      before do
        allow(Thread).to receive(:new) do |&block|
          block.call
        end
      end

      context "new assignments" do
        before do
          allow(TestTrack::Remote::SplitRegistry).to receive(:to_hash).and_return('bar' => { 'foo' => 0, 'baz' => 100 })
        end

        it "notifies unsynced assignments" do
          subject.manage do
            subject.visitor_dsl.ab('bar', true_variant: 'baz', context: :spec)
          end

          expect(Thread).to have_received(:new)
          expect(TestTrack::UnsyncedAssignmentsNotifier).to have_received(:new) do |args|
            expect(args[:mixpanel_distinct_id]).to eq('fake_distinct_id')
            expect(args[:visitor_id]).to eq('fake_visitor_id')
            args[:assignments].first.tap do |assignment|
              expect(assignment.split_name).to eq('bar')
              expect(assignment.variant).to eq('baz')
            end
          end

          expect(unsynced_assignments_notifier).to have_received(:notify)
        end

        it "does not notify unsynced assignments if there are no new assignments" do
          subject.manage {}
          expect(TestTrack::UnsyncedAssignmentsNotifier).not_to have_received(:new)
        end
      end

      context "unsynced_splits" do
        let(:remote_visitor_attributes) do
          {
            id: "fake_visitor_id",
            assignments: [
              { split_name: 'switched_split', variant: 'not_what_i_thought', unsynced: unsynced }
            ]
          }
        end

        before do
          allow(TestTrack::Remote::Visitor).to receive(:fake_instance_attributes).and_return(remote_visitor_attributes)
        end

        context "with an unsynced split" do
          let(:unsynced) { true }

          it "notifies unsynced assignments" do
            subject.manage {}

            expect(Thread).to have_received(:new)
            expect(TestTrack::UnsyncedAssignmentsNotifier).to have_received(:new) do |args|
              expect(args[:mixpanel_distinct_id]).to eq("fake_distinct_id")
              expect(args[:visitor_id]).to eq("fake_visitor_id")
              args[:assignments].first.tap do |assignment|
                expect(assignment.split_name).to eq("switched_split")
                expect(assignment.variant).to eq("not_what_i_thought")
              end
            end

            expect(unsynced_assignments_notifier).to have_received(:notify)
          end

          context "when the visitor is unknown" do
            before do
              allow(TestTrack::Remote::Visitor).to receive(:find) { raise(Faraday::TimeoutError, "woopsie") }
            end

            it "does not notify unsynced assignments" do
              subject.manage {}

              expect(TestTrack::UnsyncedAssignmentsNotifier).not_to have_received(:new)
            end
          end
        end

        context "without an unsynced split" do
          let(:unsynced) { false }

          it "does not notify unsynced assignments" do
            subject.manage {}

            expect(TestTrack::UnsyncedAssignmentsNotifier).not_to have_received(:new)
          end
        end
      end
    end

    context "aliasing" do
      before do
        allow(Delayed::Job).to receive(:enqueue).and_return(true)
      end

      it "enqueues an alias job if there was a signup" do
        expect(TestTrack::CreateAliasJob).to receive(:new).with(
          existing_mixpanel_id: 'fake_distinct_id',
          alias_id: 'fake_visitor_id'
        )

        subject.manage do
          subject.sign_up!('bettermentdb_user_id', 444)
        end

        expect(Delayed::Job).to have_received(:enqueue).with(an_instance_of(TestTrack::CreateAliasJob))
      end

      it "doesn't enqueue an alias job if there was no signup" do
        subject.manage {}
        expect(TestTrack::CreateAliasJob).not_to have_received(:new)
        expect(Delayed::Job).not_to have_received(:enqueue).with(an_instance_of(TestTrack::CreateAliasJob))
      end
    end
  end

  describe "#notify_unsynced_assignments!" do
    it "notifies in background thread" do
      notifier_thread = subject.send(:notify_unsynced_assignments!)

      expect(notifier_thread).to be_a(Thread)

      # block until thread completes
      notifier_thread.join

      expect(TestTrack::UnsyncedAssignmentsNotifier).to have_received(:new) do |args|
        expect(args[:mixpanel_distinct_id]).to eq("fake_distinct_id")
        expect(args[:visitor_id]).to eq("fake_visitor_id")
        expect(args[:assignments]).to eq([])
      end

      expect(unsynced_assignments_notifier).to have_received(:notify)
    end
  end

  describe "#visitor_dsl" do
    let(:visitor) { instance_double(TestTrack::Visitor) }

    it "is a DSL that proxies to the visitor" do
      allow(TestTrack::VisitorDSL).to receive(:new).and_call_original
      allow(TestTrack::Visitor).to receive(:new).and_return(visitor)

      subject.visitor_dsl

      expect(TestTrack::VisitorDSL).to have_received(:new).with(visitor)
    end
  end

  describe "#state_hash" do
    let(:visitor) { instance_double(TestTrack::Visitor, split_registry: "split registry", assignment_json: "assignments") }
    before do
      allow(subject).to receive(:visitor).and_return(visitor)
    end

    it "includes the test track URL" do
      expect(subject.state_hash[:url]).to eq "http://testtrack.dev"
    end

    it "includes the cookie_domain" do
      allow(request).to receive(:host).and_return("foo.bar.baz.boom.com")
      expect(subject.state_hash[:cookieDomain]).to eq(".boom.com")
    end

    it "includes the split registry" do
      expect(subject.state_hash[:registry]).to eq("split registry")
    end

    it "includes the assignment registry" do
      expect(subject.state_hash[:assignments]).to eq("assignments")
    end

    it "includes a nil :registry if visitor returns a nil split_registry" do
      allow(visitor).to receive(:split_registry).and_return(nil)
      expect(subject.state_hash).to have_key(:registry)
      expect(subject.state_hash[:registry]).to eq(nil)
    end

    it "includes a nil :assignments if visitor returns a nil assignment_registry" do
      allow(visitor).to receive(:assignment_json).and_return(nil)
      expect(subject.state_hash).to have_key(:assignments)
      expect(subject.state_hash[:assignments]).to eq(nil)
    end
  end

  describe "#log_in!" do
    let(:visitor) { subject.send(:visitor) }

    before do
      allow(visitor).to receive(:link_identifier!).and_call_original
    end

    it "calls link_identifier! on the visitor" do
      subject.log_in!('bettermentdb_user_id', 444)
      expect(visitor).to have_received(:link_identifier!).with('bettermentdb_user_id', 444)
    end

    it "returns true" do
      expect(subject.log_in!('bettermentdb_user_id', 444)).to eq true
    end
  end

  describe "#sign_up!" do
    let(:visitor) { subject.send(:visitor) }

    before do
      allow(visitor).to receive(:link_identifier!).and_call_original
    end

    it "calls link_identifier! on the visitor" do
      subject.sign_up!('bettermentdb_user_id', 444)
      expect(visitor).to have_received(:link_identifier!).with('bettermentdb_user_id', 444)
    end

    it "returns true" do
      expect(subject.sign_up!('bettermentdb_user_id', 444)).to eq true
    end
  end
end
