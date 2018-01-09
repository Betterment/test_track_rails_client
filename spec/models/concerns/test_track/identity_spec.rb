require 'rails_helper'

RSpec.describe TestTrack::Identity do
  subject { Clown.new(id: 1234) }

  describe ".test_track_identifier" do
    context "#test_track_ab" do
      let(:identity_session_discriminator) { instance_double(TestTrack::IdentitySessionDiscriminator) }
      let(:visitor_dsl) { instance_double(TestTrack::VisitorDSL, ab: false) }

      before do
        allow(TestTrack::IdentitySessionDiscriminator).to receive(:new).and_return(identity_session_discriminator)
        allow(identity_session_discriminator).to receive(:with_visitor).and_yield(visitor_dsl)
      end

      it "delegates to the session discriminator" do
        expect(subject.test_track_ab(:blue_button, context: :spec)).to be false

        expect(TestTrack::IdentitySessionDiscriminator).to have_received(:new).with(subject)
        expect(identity_session_discriminator).to have_received(:with_visitor)
        expect(visitor_dsl).to have_received(:ab).with(:blue_button, context: :spec)
      end
    end

    context "#test_track_vary" do
      def vary_side_dish
        subject.test_track_vary(:side_dish, context: :spec) do |v|
          v.when(:soup) { "soups on" }
          v.default(:salad) { "salad please" }
        end
      end

      let(:identity_session_discriminator) { instance_double(TestTrack::IdentitySessionDiscriminator) }
      let(:visitor_dsl) { instance_double(TestTrack::VisitorDSL, vary: "salad please") }

      before do
        allow(TestTrack::IdentitySessionDiscriminator).to receive(:new).and_return(identity_session_discriminator)
        allow(identity_session_discriminator).to receive(:with_visitor).and_yield(visitor_dsl)
      end

      it "delegates to the session discriminator" do
        expect(vary_side_dish).to eq "salad please"

        expect(TestTrack::IdentitySessionDiscriminator).to have_received(:new).with(subject)
        expect(identity_session_discriminator).to have_received(:with_visitor)
        expect(visitor_dsl).to have_received(:vary).with(:side_dish, context: :spec)
      end
    end

    context "#test_track_visitor_id" do
      let(:identity_session_discriminator) { instance_double(TestTrack::IdentitySessionDiscriminator) }
      let(:visitor_dsl) { instance_double(TestTrack::VisitorDSL, id: "a_fake_id") }

      before do
        allow(TestTrack::IdentitySessionDiscriminator).to receive(:new).and_return(identity_session_discriminator)
        allow(identity_session_discriminator).to receive(:with_visitor).and_yield(visitor_dsl)
      end

      it "returns the correct value from the session discriminator" do
        expect(subject.test_track_visitor_id).to eq 'a_fake_id'
      end
    end

    context "#test_track_sign_up!" do
      let(:identity_session_discriminator) { instance_double(TestTrack::IdentitySessionDiscriminator) }
      let(:session) { instance_double(TestTrack::Session) }

      before do
        allow(TestTrack::IdentitySessionDiscriminator).to receive(:new).and_return(identity_session_discriminator)
        allow(identity_session_discriminator).to receive(:with_session).and_yield(session)
        allow(session).to receive(:sign_up!)
      end

      it "delegates to the session discriminator" do
        subject.test_track_sign_up!

        expect(TestTrack::IdentitySessionDiscriminator).to have_received(:new).with(subject)
        expect(identity_session_discriminator).to have_received(:with_session)
        expect(session).to have_received(:sign_up!).with(subject)
      end
    end

    context "#test_track_log_in!" do
      let(:identity_session_discriminator) { instance_double(TestTrack::IdentitySessionDiscriminator) }
      let(:session) { instance_double(TestTrack::Session) }

      before do
        allow(TestTrack::IdentitySessionDiscriminator).to receive(:new).and_return(identity_session_discriminator)
        allow(identity_session_discriminator).to receive(:with_session).and_yield(session)
        allow(session).to receive(:log_in!)
      end

      it "delegates to the session discriminator" do
        subject.test_track_log_in! forget_current_visitor: true

        expect(TestTrack::IdentitySessionDiscriminator).to have_received(:new).with(subject)
        expect(identity_session_discriminator).to have_received(:with_session)
        expect(session).to have_received(:log_in!).with(subject, forget_current_visitor: true)
      end
    end

    context "#test_track_identifier_type" do
      it "returns the configured identifier type" do
        expect(subject.test_track_identifier_type).to eq "clown_id"
      end
    end

    context "#test_track_identifier_value" do
      it "returns the model's identifier" do
        expect(subject.test_track_identifier_value).to eq 1234
      end
    end
  end
end
