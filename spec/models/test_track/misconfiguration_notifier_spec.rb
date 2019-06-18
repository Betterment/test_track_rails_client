require 'rails_helper'

RSpec.describe TestTrack::MisconfigurationNotifier do
  subject { TestTrack::MisconfigurationNotifier::Wrapper.new }

  describe "#notify" do
    context "in development environment" do
      it "raises" do
        with_rails_env "development" do
          expect { subject.notify("something is misconfigured") }.to raise_error 'something is misconfigured'
        end
      end
    end

    context "in test environment" do
      it "does not raise" do
        with_rails_env "test" do
          expect { subject.notify("something is misconfigured") }.not_to raise_error
        end
      end
    end

    context "in production environment" do
      before do
        allow(Rails.logger).to receive(:error).and_call_original
      end

      around do |example|
        with_rails_env "production" do
          example.run
        end
      end

      it "does a rails error log" do
        subject.notify("something is misconfigured")
        expect(Rails.logger).to have_received(:error).with("something is misconfigured")
      end

      context "given an Airbrake that responds to .notify_or_ignore and .notify" do
        subject { TestTrack::MisconfigurationNotifier::Wrapper.new(TestTrack::MisconfigurationNotifier::Airbrake.new) }

        before do
          stub_const("Airbrake", double("Airbrake", notify: nil, notify_or_ignore: nil))
        end

        it "calls Airbrake.notify_or_ignore" do
          subject.notify("something is misconfigured")
          expect(::Airbrake).to have_received(:notify_or_ignore)
            .with(kind_of(StandardError), error_message: "something is misconfigured")
            .exactly(:once)
        end

        it "does not call Airbrake.notify" do
          subject.notify("something is misconfigured")
          expect(::Airbrake).not_to have_received(:notify)
        end
      end

      context "given an Airbrake that only responds to .notify" do
        subject { TestTrack::MisconfigurationNotifier::Wrapper.new(TestTrack::MisconfigurationNotifier::Airbrake.new) }

        before do
          stub_const("Airbrake", double("Airbrake", notify: nil))
        end

        it "calls Airbrake.notify" do
          subject.notify("something is misconfigured")
          expect(::Airbrake).to have_received(:notify)
            .with(kind_of(StandardError), error_message: "something is misconfigured")
            .exactly(:once)
        end
      end
    end
  end
end
