require 'rails_helper'

RSpec.describe TestTrack::Analytics::MixpanelClient do
  subject { TestTrack::Analytics::MixpanelClient.new }

  describe "#track_assignment" do
    let(:mixpanel) { instance_double(Mixpanel::Tracker, track: true) }
    let(:assignment) { instance_double(TestTrack::Assignment, visitor: 123, split_name: "foo", variant: "true", context: "bar") }
    let(:split_properties) do
      {
        SplitName: "foo",
        SplitVariant: "true",
        SplitContext: "bar",
        TTVisitorID: 123
      }
    end

    before do
      ENV['MIXPANEL_TOKEN'] = 'fakefakefake'
      allow(Mixpanel::Tracker).to receive(:new).and_return(mixpanel)
    end

    it "configures mixpanel with the token" do
      subject.track_assignment(123, assignment)

      expect(Mixpanel::Tracker).to have_received(:new).with('fakefakefake')
    end

    it "calls mixpanel track" do
      subject.track_assignment(123, assignment)

      expect(mixpanel).to have_received(:track).with(123, 'SplitAssigned', split_properties)
    end

    it "raises if mixpanel track raises Mixpanel::ConnectionError" do
      allow(mixpanel).to receive(:track) { raise Mixpanel::ConnectionError.new, "Womp womp" }
      expect { subject.track_assignment(123, assignment) }.to raise_error Mixpanel::ConnectionError, /Womp womp/
    end

    it "raises if mixpanel track fails" do
      # mock mixpanel's HTTP call to get a bit more integration coverage for mixpanel.
      # this also ensures that this test breaks if mixpanel-ruby is upgraded, since new versions react differently to 500s
      allow(Mixpanel::Tracker).to receive(:new).and_call_original
      stub_request(:post, 'https://api.mixpanel.com/track').to_return(status: 500, body: "")

      expect { subject.track_assignment(123, assignment) }.to raise_error Mixpanel::ConnectionError

      expect(WebMock).to have_requested(:post, 'https://api.mixpanel.com/track')
    end
  end
end
