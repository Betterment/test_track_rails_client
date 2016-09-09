require 'rails_helper'

RSpec.describe TestTrack::Analytics::MixpanelClient do
  subject { TestTrack::Analytics::MixpanelClient.new }

  describe "#alias" do
    let(:mixpanel) { instance_double(TestTrack::Analytics::MixpanelClient, alias: true) }

    before do
      ENV['MIXPANEL_TOKEN'] = 'fakefakefake'
      allow(Mixpanel::Tracker).to receive(:new).and_return(mixpanel)
    end

    it "configures mixpanel with the token" do
      subject.alias(123, 321)

      expect(Mixpanel::Tracker).to have_received(:new).with('fakefakefake')
    end

    it "calls mixpanel alias" do
      subject.alias(123, 321)

      expect(mixpanel).to have_received(:alias).with(123, 321)
    end

    it "raises if mixpanel alias raises" do
      allow(mixpanel).to receive(:alias) { raise StandardError.new, "Womp womp" }
      expect { subject.alias(123, 321) }.to raise_error StandardError, /Womp womp/
    end

    it "raises if mixpanel alias connection fails" do
      # mock mixpanel's HTTP call to get a bit more integration coverage for mixpanel.
      # this also ensures that this test breaks if mixpanel-ruby is upgraded, since new versions react differently to 500s
      allow(Mixpanel::Tracker).to receive(:new).and_call_original
      stub_request(:post, 'https://api.mixpanel.com/track').to_return(status: 500, body: "")
      expect { subject.alias(123, 321) }.to raise_error Mixpanel::ConnectionError

      expect(WebMock).to have_requested(:post, 'https://api.mixpanel.com/track')
    end
  end

  describe "#track" do
    let(:mixpanel) { instance_double(TestTrack::Analytics::MixpanelClient, track: true) }

    before do
      ENV['MIXPANEL_TOKEN'] = 'fakefakefake'
      allow(Mixpanel::Tracker).to receive(:new).and_return(mixpanel)
    end

    it "configures mixpanel with the token" do
      subject.track(123, 'Metric')

      expect(Mixpanel::Tracker).to have_received(:new).with('fakefakefake')
    end

    it "calls mixpanel track" do
      subject.track(123, 'Metric', foo: 'bar')

      expect(mixpanel).to have_received(:track).with(123, 'Metric', foo: 'bar')
    end

    it "returns false if mixpanel track raises Mixpanel::ConnectionError" do
      allow(mixpanel).to receive(:track) { raise Mixpanel::ConnectionError.new, "Womp womp" }
      expect { subject.track(123, 'Metric') }.to raise_error Mixpanel::ConnectionError, /Womp womp/
    end

    it "returns false if mixpanel track fails" do
      # mock mixpanel's HTTP call to get a bit more integration coverage for mixpanel.
      # this also ensures that this test breaks if mixpanel-ruby is upgraded, since new versions react differently to 500s
      allow(Mixpanel::Tracker).to receive(:new).and_call_original
      stub_request(:post, 'https://api.mixpanel.com/track').to_return(status: 500, body: "")

      expect { subject.track(123, 'Metric') }.to raise_error Mixpanel::ConnectionError

      expect(WebMock).to have_requested(:post, 'https://api.mixpanel.com/track')
    end
  end
end
