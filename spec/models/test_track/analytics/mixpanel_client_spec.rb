require 'rails_helper'

RSpec.describe TestTrack::Analytics::MixpanelClient do
  subject { TestTrack::Analytics::MixpanelClient.new }

  describe "#track" do
    let(:mixpanel) { instance_double(Mixpanel::Tracker, track: true) }
    let(:analytics_event) do
      instance_double(
        TestTrack::AnalyticsEvent,
        visitor_id: 123,
        name: "split_assigned",
        properties: split_properties
      )
    end
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
      subject.track(analytics_event)

      expect(Mixpanel::Tracker).to have_received(:new).with('fakefakefake')
    end

    it "calls mixpanel track" do
      subject.track(analytics_event)

      expect(mixpanel).to have_received(:track).with(123, 'split_assigned', split_properties)
    end

    it "raises if mixpanel track raises Mixpanel::ConnectionError" do
      allow(mixpanel).to receive(:track) { raise Mixpanel::ConnectionError.new, "Womp womp" }
      expect { subject.track(analytics_event) }.to raise_error Mixpanel::ConnectionError, /Womp womp/
    end

    it "raises if mixpanel track fails" do
      # mock mixpanel's HTTP call to get a bit more integration coverage for mixpanel.
      # this also ensures that this test breaks if mixpanel-ruby is upgraded, since new versions react differently to 500s
      allow(Mixpanel::Tracker).to receive(:new).and_call_original
      stub_request(:post, 'https://api.mixpanel.com/track').to_return(status: 500, body: "")

      expect { subject.track(analytics_event) }.to raise_error Mixpanel::ConnectionError

      expect(WebMock).to have_requested(:post, 'https://api.mixpanel.com/track')
    end
  end
end
