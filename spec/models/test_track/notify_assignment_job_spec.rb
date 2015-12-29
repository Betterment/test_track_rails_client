require 'rails_helper'

RSpec.describe TestTrack::NotifyAssignmentJob do
  let(:params) do
    {
      mixpanel_distinct_id: "fake_mixpanel_id",
      visitor_id: "fake_visitor_id",
      split_name: "phaser",
      variant: "stun"
    }
  end

  subject { described_class.new(params) }

  it "blows up with empty mixpanel_distinct_id" do
    expect { described_class.new(params.merge(mixpanel_distinct_id: '')) }
      .to raise_error(/mixpanel_distinct_id/)
  end

  it "blows up with empty visitor id" do
    expect { described_class.new(params.merge(visitor_id: nil)) }
      .to raise_error(/visitor_id/)
  end

  it "blows up with empty split_name" do
    expect { described_class.new(params.merge(split_name: '')) }
      .to raise_error(/split_name/)
  end

  it "blows up with empty variant" do
    expect { described_class.new(params.merge(variant: '')) }
      .to raise_error(/variant/)
  end

  it "blows up with unknown opts" do
    expect { described_class.new(params.merge(extra_stuff: true)) }
      .to raise_error(/unknown opts/)
  end

  describe "#perform" do
    let(:mixpanel) { instance_double(Mixpanel::Tracker, track: true) }
    before do
      allow(Mixpanel::Tracker).to receive(:new).and_return(mixpanel)
      allow(TestTrack::Remote::Assignment).to receive(:create!).and_call_original
      ENV['MIXPANEL_TOKEN'] = 'fakefakefake'
    end

    it "configures mixpanel with the token" do
      subject.perform
      expect(Mixpanel::Tracker).to have_received(:new).with("fakefakefake")
    end

    it "sends mixpanel event" do
      subject.perform

      expect(mixpanel).to have_received(:track).with(
        "fake_mixpanel_id",
        "SplitAssigned",
        "SplitName" => 'phaser',
        "SplitVariant" => 'stun',
        "TTVisitorID" => "fake_visitor_id"
      )
    end

    it "sends test_track assignment" do
      subject.perform

      expect(TestTrack::Remote::Assignment).to have_received(:create!).with(
        visitor_id: 'fake_visitor_id',
        split: 'phaser',
        variant: 'stun',
        mixpanel_result: 'success'
      )
    end

    context "mixpanel track fails" do
      it "sends test_track assignment with mixpanel_result set to failure" do
        # mock mixpanel's HTTP call to get a bit more integration coverage for mixpanel.
        # this also ensures that this test breaks if mixpanel-ruby is upgraded, since new versions react differently to 500s
        allow(Mixpanel::Tracker).to receive(:new).and_call_original
        stub_request(:post, 'https://api.mixpanel.com/track').to_return(status: 500, body: "")

        subject.perform

        expect(WebMock).to have_requested(:post, 'https://api.mixpanel.com/track')

        expect(TestTrack::Remote::Assignment).to have_received(:create!).with(
          visitor_id: 'fake_visitor_id',
          split: 'phaser',
          variant: 'stun',
          mixpanel_result: 'failure'
        )
      end
    end
  end
end
