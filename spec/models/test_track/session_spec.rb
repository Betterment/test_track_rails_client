require 'rails_helper'

RSpec.describe TestTrack::Session do
  let(:identity) { Clown.new(id: 1234) }

  let(:controller_class) do
    Class.new(ApplicationController) do
      include TestTrack::Controller

      private # make current_clown private to better simulate real world scenario

      def current_clown; end
    end
  end

  let(:controller) { controller_class.new }

  let(:cookies) { { tt_visitor_id: "fake_visitor_id", mp_fakefakefake_mixpanel: mixpanel_cookie }.with_indifferent_access }
  let(:headers) { {} }
  let(:mixpanel_cookie) { { distinct_id: "fake_distinct_id", OtherProperty: "bar" }.to_json }
  let(:request) { double(:request, host: "www.foo.com", ssl?: true, headers: headers) }
  let(:response) { double(:response, headers: {}) }
  let(:unsynced_assignments_notifier) { instance_double(TestTrack::UnsyncedAssignmentsNotifier, notify: true) }

  subject { described_class.new(controller) }

  before do
    allow(controller).to receive(:cookies).and_return(cookies)
    allow(controller).to receive(:request).and_return(request)
    allow(controller).to receive(:response).and_return(response)
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
          subject.log_in!(identity)

          expect(TestTrack::Remote::Identifier).to have_received(:create!).with(
            identifier_type: "clown_id",
            visitor_id: "fake_visitor_id",
            value: "1234"
          )
        end
      end

      it "sets correct tt_visitor_id" do
        subject.manage do
          subject.log_in!(identity)
        end
        expect(cookies['tt_visitor_id'][:value]).to eq "real_visitor_id"
      end

      context 'test track visitor id is the same as existing visitor id' do
        before do
          real_visitor = instance_double(TestTrack::Visitor, id: "fake_visitor_id", assignment_registry: {})
          identifier = instance_double(TestTrack::Remote::Identifier, visitor: real_visitor)
          allow(TestTrack::Remote::Identifier).to receive(:create!).and_return(identifier)
        end

        it "does not return the visitor id in the reponse header" do
          subject.manage do
            subject.log_in!(identity)
          end

          expect(controller.response.headers).not_to have_key('X-Set-TT-Visitor-ID')
        end
      end

      context 'test track visitor id differs from existing visitor id' do
        before do
          real_visitor = instance_double(TestTrack::Visitor, id: "real_visitor_id", assignment_registry: {})
          identifier = instance_double(TestTrack::Remote::Identifier, visitor: real_visitor)
          allow(TestTrack::Remote::Identifier).to receive(:create!).and_return(identifier)
        end

        it "returns the existing visitor id in the reponse header" do
          subject.manage do
            subject.log_in!(identity)
          end

          expect(controller.response.headers['X-Set-TT-Visitor-ID']).to eq('real_visitor_id')
        end
      end

      it "changes the distinct_id in the mixpanel cookie" do
        subject.manage do
          subject.log_in!(identity)
        end
        expect(cookies['mp_fakefakefake_mixpanel'][:value]).to eq({ distinct_id: "real_visitor_id", OtherProperty: "bar" }.to_json)
      end

      context "forget current visitor" do
        before do
          allow(TestTrack::Visitor).to receive(:new).and_call_original
        end

        it "creates a temporary visitor when creating the identifier" do
          subject.manage do
            subject.log_in!(identity, forget_current_visitor: true)
          end

          expect(TestTrack::Visitor).to have_received(:new)
          expect(TestTrack::Remote::Identifier).to have_received(:create!).with(
            identifier_type: "clown_id",
            visitor_id: /\A[a-f0-9\-]{36}\z/,
            value: "1234"
          )
        end
      end
    end

    context "current visitor id is passed via the header" do
      let(:cookies) { {} }
      let(:headers) { { 'X-TT-Visitor-ID' => 'fake_visitor_id' } }

      before do
        real_visitor = instance_double(TestTrack::Visitor, id: "real_visitor_id", assignment_registry: {})
        identifier = instance_double(TestTrack::Remote::Identifier, visitor: real_visitor)
        allow(TestTrack::Remote::Identifier).to receive(:create!).and_return(identifier)
      end

      describe '#sign_up!' do
        it "provides the current visitor id when requesting an identifier" do
          subject.manage do
            subject.sign_up!(identity)

            expect(TestTrack::Remote::Identifier).to have_received(:create!).with(
              identifier_type: "clown_id",
              visitor_id: "fake_visitor_id",
              value: "1234"
            )
          end
        end
      end

      describe '#log_in!' do
        it "provides the current visitor id when requesting an identifier" do
          subject.manage do
            subject.log_in!(identity)

            expect(TestTrack::Remote::Identifier).to have_received(:create!).with(
              identifier_type: "clown_id",
              visitor_id: "fake_visitor_id",
              value: "1234"
            )
          end
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
          CGI.escape("{\"distinct_id\": \"fake_distinct_id\", \"referrer\":\"http://bad.com/?q=\"bad\"\"}")
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
      it "uses the default cookie name when not configured" do
        subject.manage {}
        expect(cookies).to include 'tt_visitor_id'
      end

      it "uses the custom cookie name when configured" do
        with_env TEST_TRACK_VISITOR_COOKIE_NAME: 'custom_cookie_name' do
          subject.manage {}
          expect(cookies).to include 'custom_cookie_name'
        end
      end

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

      it "uses the fully qualified cookie domain when enabled and there is no subdomain" do
        with_env TEST_TRACK_FULLY_QUALIFIED_COOKIE_DOMAIN_ENABLED: 1 do
          allow(request).to receive(:host).and_return("foo.com")
          subject.manage {}
          expect(cookies['tt_visitor_id'][:domain]).to eq "foo.com"
        end
      end

      it "uses the fully qualified cookie domain when enabled and there is a subdomain" do
        with_env TEST_TRACK_FULLY_QUALIFIED_COOKIE_DOMAIN_ENABLED: 1 do
          allow(request).to receive(:host).and_return("foo.bar.baz.boom.com")
          subject.manage {}
          expect(cookies['tt_visitor_id'][:domain]).to eq "foo.bar.baz.boom.com"
        end
      end

      it "checks for a valid domain" do
        allow(request).to receive(:host).and_return("a.bad.actor;did-this<luzer>")
        expect { subject.manage {} }.to raise_error PublicSuffix::DomainInvalid
      end

      it "checks for a valid domain when fully qualified cookie domains are enabled" do
        with_env TEST_TRACK_FULLY_QUALIFIED_COOKIE_DOMAIN_ENABLED: 1 do
          allow(request).to receive(:host).and_return("a.bad.actor;did-this<luzer>")
          expect { subject.manage {} }.to raise_error PublicSuffix::DomainInvalid
        end
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
      let(:registry) do
        {
          'bar' => { 'foo' => 0, 'baz' => 100 },
          'switched_split' => { 'not_what_i_thought' => 100, 'originally_me' => 0 }
        }
      end

      before do
        allow(Thread).to receive(:new) do |*args, &block|
          block.call(*args)
        end

        allow(TestTrack::Remote::SplitRegistry).to receive(:to_hash).and_return(registry)
      end

      context "new assignments" do
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

          context 'when the test track visitor is not yet loaded' do
            it 'does not trigger a load of the assignments' do
              subject.manage {}

              expect(TestTrack::UnsyncedAssignmentsNotifier).not_to have_received(:new)
            end
          end

          context 'when the test track visitor is loaded' do
            it "notifies unsynced assignments" do
              subject.manage do
                subject.visitor_dsl.ab('bar', true_variant: 'baz', context: :spec)
              end

              expect(Thread).to have_received(:new)
              expect(TestTrack::UnsyncedAssignmentsNotifier).to have_received(:new) do |args|
                expect(args[:mixpanel_distinct_id]).to eq("fake_distinct_id")
                expect(args[:visitor_id]).to eq("fake_visitor_id")
                args[:assignments].first.tap do |assignment|
                  expect(assignment.split_name).to eq("switched_split")
                  expect(assignment.variant).to eq("not_what_i_thought")
                end
                args[:assignments].second.tap do |assignment|
                  expect(assignment.split_name).to eq("bar")
                  expect(assignment.variant).to eq("baz")
                end
              end

              expect(unsynced_assignments_notifier).to have_received(:notify)
            end
          end

          context "when the visitor is unknown" do
            before do
              allow(TestTrack::Remote::Visitor).to receive(:find) { raise(Faraday::TimeoutError, "woopsie") }
            end

            it "does not notify unsynced assignments" do
              subject.manage do
                subject.visitor_dsl.ab('bar', true_variant: 'baz', context: :spec)
              end

              expect(TestTrack::UnsyncedAssignmentsNotifier).not_to have_received(:new)
            end
          end
        end

        context "without an unsynced split" do
          let(:unsynced) { false }

          it "does not notify unsynced assignments" do
            subject.manage do
              subject.visitor_dsl.ab('switched_split', true_variant: 'not_what_i_thought', context: :spec)
            end

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
          existing_id: 'fake_distinct_id',
          alias_id: 'fake_visitor_id'
        )

        subject.manage do
          subject.sign_up!(identity)
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

    let(:notifier) { instance_double(TestTrack::UnsyncedAssignmentsNotifier) }

    it "passes along RequestStore contents to the background thread" do
      RequestStore[:stashed_object] = 'stashed object'
      found_object = nil

      allow(TestTrack::UnsyncedAssignmentsNotifier).to receive(:new).and_return(notifier)
      allow(notifier).to receive(:notify) do
        found_object = RequestStore[:stashed_object]
      end

      notifier_thread = subject.send(:notify_unsynced_assignments!)

      # block until thread completes
      notifier_thread.join

      expect(found_object).to eq 'stashed object'
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

    it "includes the cookie_name" do
      expect(subject.state_hash[:cookieName]).to eq("tt_visitor_id")
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
      subject.log_in!(identity)
      expect(visitor).to have_received(:link_identifier!).with('clown_id', 1234)
    end

    it "returns true" do
      expect(subject.log_in!(identity)).to eq true
    end

    it "allows identity type and value arguments with a warning" do
      expect {
        subject.log_in!('identity_type', 'identity_value')
      }.to output(/#log_in! with two args is deprecated. Please provide a TestTrack::Identity/).to_stderr
    end
  end

  describe "#sign_up!" do
    let(:visitor) { subject.send(:visitor) }

    before do
      allow(visitor).to receive(:link_identifier!).and_call_original
    end

    it "calls link_identifier! on the visitor" do
      subject.sign_up!(identity)
      expect(visitor).to have_received(:link_identifier!).with('clown_id', 1234)
    end

    it "returns true" do
      expect(subject.sign_up!(identity)).to eq true
    end

    it "allows identity type and value arguments with a warning" do
      expect {
        subject.sign_up!('identity_type', 'identity_value')
      }.to output(/#sign_up! with two args is deprecated. Please provide a TestTrack::Identity/).to_stderr
    end
  end

  describe "#has_matching_identity?" do
    context "when the controller's authenticated resource matches the identity" do
      before do
        allow(controller).to receive(:current_clown).and_return(identity)
      end

      it "returns true" do
        expect(subject.has_matching_identity?(identity)).to eq true
      end
    end

    context "when the controller's authenticated resource does not match the identity" do
      let(:other_identity) { Clown.new(id: 9876) }

      before do
        allow(controller).to receive(:current_clown).and_return(other_identity)
      end

      it "returns false" do
        expect(subject.has_matching_identity?(identity)).to eq false
      end
    end

    context "when the identity matches a previously logged in identity" do
      it "returns true" do
        expect(subject.has_matching_identity?(identity)).to eq false

        subject.log_in!(identity)

        expect(subject.has_matching_identity?(identity)).to eq true
      end
    end

    context "when the identity matches a previously signed up identity" do
      it "returns true" do
        expect(subject.has_matching_identity?(identity)).to eq false

        subject.sign_up!(identity)

        expect(subject.has_matching_identity?(identity)).to eq true
      end
    end
  end
end
