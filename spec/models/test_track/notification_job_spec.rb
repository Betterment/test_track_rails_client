require 'rails_helper'

RSpec.describe TestTrack::NotificationJob do
  let(:params) { { mixpanel_distinct_id: "fake_mixpanel_id", visitor_id: "fake_visitor_id", new_assignments: new_assignments } }
  let(:new_assignments) { { 'blue_button' => 'true', 'phaser' => 'stun' } }

  subject { described_class.new(params) }

  it "blows up with empty mixpanel_distinct_id" do
    expect { described_class.new(params.merge(mixpanel_distinct_id: '')) }
      .to raise_error(/mixpanel_distinct_id/)
  end

  it "blows up with empty visitor id" do
    expect { described_class.new(params.merge(visitor_id: nil)) }
      .to raise_error(/visitor_id/)
  end

  it "blows up with empty assignments" do
    expect { described_class.new(params.merge(new_assignments: {})) }
      .to raise_error(/new_assignments/)
  end

  it "blows up with unknown opts" do
    expect { described_class.new(params.merge(extra_stuff: true)) }
      .to raise_error(/unknown opts/)
  end

  describe "#perform" do
    let(:mixpanel) { instance_double(Mixpanel::Tracker, track: true) }
    before do
      allow(Mixpanel::Tracker).to receive(:new).and_return(mixpanel)
      allow(TestTrack::Assignment).to receive(:create!).and_call_original
      ENV['MIXPANEL_TOKEN'] = 'fakefakefake'
    end

    it "configures mixpanel with the token" do
      subject.perform
      expect(Mixpanel::Tracker).to have_received(:new).with("fakefakefake")
    end

    it "sends mixpanel events" do
      subject.perform

      expect(mixpanel).to have_received(:track).with(
        "fake_mixpanel_id",
        "SplitAssigned",
        "SplitName" => 'blue_button',
        "SplitVariant" => 'true',
        "TTVisitorID" => "fake_visitor_id"
      )

      expect(mixpanel).to have_received(:track).with(
        "fake_mixpanel_id",
        "SplitAssigned",
        "SplitName" => 'phaser',
        "SplitVariant" => 'stun',
        "TTVisitorID" => "fake_visitor_id"
      )
    end

    it "sends test_track assignments" do
      subject.perform

      expect(TestTrack::Assignment).to have_received(:create!).with(
        visitor_id: 'fake_visitor_id',
        split_name: 'blue_button',
        variant: 'true'
      )
      expect(TestTrack::Assignment).to have_received(:create!).with(
        visitor_id: 'fake_visitor_id',
        split_name: 'phaser',
        variant: 'stun'
      )
    end
  end
end
