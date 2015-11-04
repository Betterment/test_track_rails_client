require 'rails_helper'

RSpec.describe TestTrack::VaryDSL do
  subject do
    described_class.new(
      split_name: :button_size,
      assigned_variant: :one,
      split_registry: split_registry
    )
  end
  let(:split_registry) do
    {
      'button_size' => {
        'one' => 100,
        'two' => 0,
        'three' => 0,
        'four' => 0
      },
      'time' => {
        'hammertime' => 50,
        'clobberin_time' => 50
      }
    }
  end
  let(:noop) { -> {} }

  before do
    allow(Airbrake).to receive(:notify_or_ignore).and_call_original
  end

  it "isn't defaulted by default" do
    expect(subject.defaulted?).to be_falsey
  end

  context "#initialize" do
    it "raises when given an unknown option" do
      expect do
        described_class.new(
          split_name: :button_size,
          assigned_variant: :one,
          split_registry: split_registry,
          one_of_these_things_is_not_like_the_other: "hint: its me!"
        )
      end.to raise_error("unknown opts: one_of_these_things_is_not_like_the_other")
    end

    it "raises when missing a required option" do
      expect do
        described_class.new(
          assigned_variant: :one,
          split_registry: split_registry
        )
      end.to raise_error("Must provide split_name")
    end
  end

  context "#run" do
    it "tells errbit if all variants aren't covered" do
      subject.when(:one) { "hello!" }
      subject.default :two, &noop

      expect(subject.send :run).to eq "hello!"
      expect(Airbrake).to have_received(:notify_or_ignore).with("vary for \"button_size\" does not configure variants three and four")
    end

    context "with a nil split_registry" do
      let(:split_registry) { nil }

      before do
        subject.when(:one) { "hello!" }
        subject.default :two, &noop
      end

      it "still runs the correct proc" do
        expect(subject.send :run).to eq "hello!"
      end

      it "doesn't alert airbrake about misconfiguration" do
        expect(Airbrake).not_to have_received(:notify_or_ignore)
      end
    end

    context "with a nil assignment" do
      before do
        subject.when(:one) { "regular" }
        subject.default(:two) { "default" }
      end

      subject do
        described_class.new(
          split_name: :button_size,
          assigned_variant: nil,
          split_registry: split_registry
        )
      end

      it "runs the default proc" do
        expect(subject.send(:run)).to eq "default"
      end
    end
  end

  context "#when" do
    it "requires at least one variant" do
      expect { subject.when { "huh?" } }.to raise_error("must provide at least one variant")
    end

    it "supports multiple variants" do
      subject.when :one, :two, :three, &noop

      expect(subject.send(:variant_procs).size).to eq 3
      expect(subject.send(:variant_procs).keys).to eq %w(one two three)
    end

    it "tells errbit if variant not in registry" do
      subject.when :this_does_not_exist, &noop

      expect(Airbrake).to have_received(:notify_or_ignore).with('vary for "button_size" configures unknown variant "this_does_not_exist"')
    end

    it "tells errbit about only invalid variant(s)" do
      subject.when :this_does_not_exist, :two, :three, :and_neither_does_this_one, &noop

      expect(Airbrake).to have_received(:notify_or_ignore)
        .with('vary for "button_size" configures unknown variant "this_does_not_exist"')
      expect(Airbrake).to have_received(:notify_or_ignore)
        .with('vary for "button_size" configures unknown variant "and_neither_does_this_one"')
    end

    context "with a nil split_registry" do
      let(:split_registry) { nil }

      it "assumes all variants are valid" do
        subject.when :something_random, &noop

        expect(Airbrake).not_to have_received(:notify_or_ignore)
      end
    end
  end

  context "#default" do
    it "accepts a block" do
      subject.when :one do
        puts "hello"
      end

      expect(subject.send(:variant_procs).size).to eq 1
      expect(subject.send(:variant_procs)['one']).to be_a Proc
      expect(subject.send(:variant_procs)[:one]).to be_nil
    end

    it "tells errbit if variant not in registry" do
      subject.default :this_default_does_not_exist, &noop

      expect(Airbrake).to have_received(:notify_or_ignore)
        .with('vary for "button_size" configures unknown variant "this_default_does_not_exist"')
    end

    context "with a nil split_registry" do
      let(:split_registry) { nil }

      it "assumes all variants are valid" do
        subject.default :something_random, &noop

        expect(Airbrake).not_to have_received(:notify_or_ignore)
      end
    end
  end
end
