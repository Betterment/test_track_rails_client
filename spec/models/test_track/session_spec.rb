require 'rails_helper'

RSpec.describe TestTrack::Session do
  let(:identity) { Clown.new(id: 1234) }

  let(:controller_class) do
    Class.new(ApplicationController) do
      include TestTrack::Controller

      self.test_track_identity = :current_clown

      private # make current_clown private to better simulate real world scenario

      def current_clown; end
    end
  end

  let(:controller) { controller_class.new }

  let(:cookies) { { tt_visitor_id: "fake_visitor_id" }.with_indifferent_access }
  let(:headers) { {} }
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
  end

  describe "#manage" do
    context "visitor" do
      it "sets a visitor ID cookie" do
        subject.manage {}
        expect(cookies['tt_visitor_id'][:value]).to eq "fake_visitor_id"
      end

      context "with no visitor cookie" do
        let(:cookies) { {} }

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

        context 'when analytics client implements sign_up!' do
          let(:client) { double("Client") }

          around do |example|
            RSpec::Mocks.with_temporary_scope do
              default_client = TestTrack.analytics
              begin
                TestTrack.analytics = TestTrack::Analytics::SafeWrapper.new(client)
                example.run
              ensure
                TestTrack.analytics = default_client
              end
            end
          end

          it 'calls sign_up! on analytics client' do
            expect(client).to receive(:sign_up!)
            subject.manage { subject.sign_up!(identity) }
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

      it "works with localhost" do
        allow(request).to receive(:host).and_return("localhost")
        subject.manage {}
        expect(cookies['tt_visitor_id'][:domain]).to eq ".localhost"
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
          'splits' => {
            'bar' => {
              'weights' => { 'foo' => 0, 'baz' => 100 },
              'feature_gate' => false
            },
            'switched_split' => {
              'weights' => { 'not_what_i_thought' => 100, 'originally_me' => 0 },
              'feature_gate' => false
            }
          },
          'experience_sampling_weight' => 1
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
            expect(args[:visitor_id]).to eq('fake_visitor_id')
            args[:assignments].first.tap do |assignment|
              expect(assignment.split_name).to eq('bar')
              expect(assignment.variant).to eq('baz')
            end
          end

          expect(unsynced_assignments_notifier).to have_received(:notify)
        end

        it "notifies unsynced assignments for identities" do
          subject.manage do
            subject.visitor_dsl_for(identity).ab('bar', true_variant: 'baz', context: :spec)
          end

          expect(Thread).to have_received(:new)
          expect(TestTrack::UnsyncedAssignmentsNotifier).to have_received(:new) do |args|
            expect(args[:visitor_id]).to eq('fake_visitor_id')
            args[:assignments].first.tap do |assignment|
              expect(assignment.split_name).to eq('bar')
              expect(assignment.variant).to eq('baz')
            end
          end
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
  end

  describe "#visitor_dsl_for" do
    before do
      allow(TestTrack::Remote::Visitor).to receive(:from_identifier).and_call_original
    end

    context "when the controller has no authenticated resource" do
      before do
        allow(controller).to receive(:current_clown).and_return(nil)
      end

      it "fetches a remote visitor by identity" do
        visitor_dsl = subject.visitor_dsl_for(identity)
        expect(visitor_dsl).to be_a TestTrack::VisitorDSL
        visitor_dsl.id

        expect(TestTrack::Remote::Visitor).to have_received(:from_identifier).with('clown_id', 1234)
      end
    end

    context "when the controller's authenticated resource matches the requested identity" do
      before do
        allow(controller).to receive(:current_clown).and_return(identity)
      end

      it "fetches the remote visitor by identity instead of by visitor_id for security" do
        visitor_dsl = subject.visitor_dsl_for(identity)
        expect(visitor_dsl).to be_a TestTrack::VisitorDSL
        visitor_dsl.id

        expect(TestTrack::Remote::Visitor).to have_received(:from_identifier).with('clown_id', 1234)
      end
    end

    context "when the controller's authenticated resource does not match the identity" do
      let(:other_identity) { Clown.new(id: 9876) }

      before do
        allow(controller).to receive(:current_clown).and_return(other_identity)
      end

      it "fetches a remote visitor by identity" do
        visitor_dsl = subject.visitor_dsl_for(identity)
        expect(visitor_dsl).to be_a TestTrack::VisitorDSL
        visitor_dsl.id

        expect(TestTrack::Remote::Visitor).to have_received(:from_identifier).with('clown_id', 1234)
      end
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

    context "with authentication disabled" do
      before do
        controller.class.test_track_identity = :none
      end

      it "returns a visitor-seeded DSL" do
        allow(TestTrack::VisitorDSL).to receive(:new).and_call_original
        allow(TestTrack::Visitor).to receive(:new).and_return(visitor)

        subject.visitor_dsl

        expect(TestTrack::VisitorDSL).to have_received(:new).with(visitor)
      end
    end

    context "with a current identity" do
      let(:clown) { double(test_track_identifier_type: 'clown_id', test_track_identifier_value: '132') }
      let(:visitor) { instance_double(TestTrack::Remote::Visitor, id: 'an id for real', assignments: {}) }

      before do
        my_clown = clown
        controller_class.class_eval do
          define_method(:current_clown) do
            my_clown
          end
        end

        allow(TestTrack::Remote::Visitor).to receive(:from_identifier).and_return(visitor)
      end

      it "returns a visitor looked up by identity" do
        subject.visitor_dsl.id

        expect(TestTrack::Remote::Visitor).to have_received(:from_identifier).with('clown_id', '132')
      end
    end
  end

  describe "#state_hash" do
    let(:v1_split_registry) do
      {
        'split_name' => {
          'variant_1' => 100,
          'variant_2' => 0
        }
      }
    end

    let(:split_registry) { instance_double(TestTrack::SplitRegistry) }
    let(:visitor) { instance_double(TestTrack::Visitor, split_registry: split_registry, assignment_json: "assignments") }
    before do
      allow(subject).to receive(:current_visitor).and_return(visitor)
      allow(split_registry).to receive(:to_v1_hash).and_return(v1_split_registry)
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

    it "includes the v1-ified split registry" do
      expect(subject.state_hash[:registry]).to eq(v1_split_registry)
    end

    it "includes the assignment registry" do
      expect(subject.state_hash[:assignments]).to eq("assignments")
    end

    it "includes a nil :registry if visitor returns a nil split_registry" do
      allow(split_registry).to receive(:to_v1_hash).and_return(nil)
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
    let(:visitor) { subject.send(:current_visitor) }

    before do
      allow(visitor).to receive(:link_identity!).and_call_original
    end

    it "calls link_identity! on the visitor" do
      subject.log_in!(identity)
      expect(visitor).to have_received(:link_identity!).with(identity)
    end

    it "returns true" do
      expect(subject.log_in!(identity)).to eq true
    end
  end

  describe "#sign_up!" do
    let(:visitor) { subject.send(:current_visitor) }

    before do
      allow(visitor).to receive(:link_identity!).and_call_original
    end

    it "calls link_identity! on the visitor" do
      subject.sign_up!(identity)
      expect(visitor).to have_received(:link_identity!).with(identity)
    end

    it "returns true" do
      expect(subject.sign_up!(identity)).to eq true
    end
  end
end
