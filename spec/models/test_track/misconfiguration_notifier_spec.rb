require 'rails_helper'

RSpec.describe TestTrack::MisconfigurationNotifier do
  subject { TestTrack::MisconfigurationNotifier.new }

  describe "#notify" do
    before do
      allow(Rails.logger).to receive(:error).and_call_original
    end

    it "does a rails error log" do
      subject.notify("something is misconfigured")
      expect(Rails.logger).to have_received(:error).with("something is misconfigured")
    end

    context "given an Airbrake that responds to .notify_or_ignore and .notify" do
      before do
        stub_const("Airbrake", double("Airbrake", notify: nil, notify_or_ignore: nil))
      end

      it "calls Airbrake.notify_or_ignore" do
        subject.notify("something is misconfigured")
        expect(Airbrake).to have_received(:notify_or_ignore).with("something is misconfigured").exactly(:once)
      end

      it "does not call Airbrake.notify" do
        subject.notify("something is misconfigured")
        expect(Airbrake).not_to have_received(:notify)
      end
    end

    context "given an Airbrake that only responds to .notify" do
      before do
        stub_const("Airbrake", double("Airbrake", notify: nil))
      end

      it "calls Airbrake.notify" do
        subject.notify("something is misconfigured")
        expect(Airbrake).to have_received(:notify).with("something is misconfigured").exactly(:once)
      end
    end
  end
end
