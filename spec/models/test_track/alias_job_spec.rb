require 'rails_helper'

RSpec.describe TestTrack::AliasJob do
  let(:params) { { mixpanel_distinct_id: "fake_mixpanel_id", visitor_id: "fake_visitor_id" } }

  subject { described_class.new(params) }

  it "blows up with empty mixpanel_distinct_id" do
    expect { described_class.new(params.merge(mixpanel_distinct_id: '')) }
      .to raise_error(/mixpanel_distinct_id/)
  end

  it "blows up with empty visitor id" do
    expect { described_class.new(params.merge(visitor_id: nil)) }
      .to raise_error(/visitor_id/)
  end

  it "blows up with unknown opts" do
    expect { described_class.new(params.merge(extra_stuff: true)) }
      .to raise_error(/unknown opts/)
  end

  describe "#perform" do
    let(:mixpanel) { instance_double(Mixpanel::Tracker, alias: true) }
    before do
      allow(Mixpanel::Tracker).to receive(:new).and_return(mixpanel)
      ENV['MIXPANEL_TOKEN'] = 'fakefakefake'
    end

    it "configures mixpanel with the token" do
      subject.perform
      expect(Mixpanel::Tracker).to have_received(:new).with("fakefakefake")
    end

    it "sends mixpanel events" do
      subject.perform
      expect(mixpanel).to have_received(:alias).with("fake_visitor_id", "fake_mixpanel_id")
    end
  end
end
