require 'rails_helper'

RSpec.describe TestTrack::Analytics::SafeWrapper do
  let(:underlying) { double("Client", track_assignment: true, alias: false) }

  subject { TestTrack::Analytics::SafeWrapper.new(underlying) }

  describe '#alias' do
    it 'calls underlying' do
      expect(subject.alias(123, 321)).to eq true
      expect(underlying).to have_received(:alias).with(123, 321)
    end

    context 'underlying raises' do
      it 'returns false' do
        allow(underlying).to receive(:alias).and_raise StandardError

        expect(subject.alias(123, 321)).to eq false
        expect(underlying).to have_received(:alias).with(123, 321)
      end
    end
  end

  describe '#track_assignment' do
    it 'calls underlying' do
      expect(subject.track_assignment(123, foo: "bar")).to eq true
      expect(underlying).to have_received(:track_assignment).with(123, { foo: "bar" }, {})
    end

    context 'underlying raises' do
      it 'returns false' do
        allow(underlying).to receive(:track_assignment).and_raise StandardError

        expect(subject.track_assignment(123, {})).to eq false
        expect(underlying).to have_received(:track_assignment).with(123, {}, {})
      end
    end
  end

  describe 'error handling' do
    let(:error) { StandardError.new("Something went wrong") }

    before do
      allow(underlying).to receive(:track_assignment).and_raise error
    end

    context 'when Airbrake is loaded' do
      before do
        stub_const('Airbrake', double('Airbrake', notify: true))
        allow(Airbrake).to receive(:notify)
      end

      it 'calls Airbrake.notify' do
        subject.track_assignment(123, {})

        expect(Airbrake).to have_received(:notify).with(error)
      end
    end

    context 'when Airbrake is not loaded' do
      before do
        allow(Object).to receive(:const_defined?).and_call_original
        allow(Object).to receive(:const_defined?).with(:Airbrake).and_return false
        allow(Rails.logger).to receive(:error)
      end

      it 'logs error to Rails.logger' do
        subject.track_assignment(123, {})

        expect(Rails.logger).to have_received(:error).with(error)
      end
    end

    context 'when custom lambda provided' do
      let(:handler) { ->(_) { nil } }

      before do
        subject.error_handler = handler

        allow(handler).to receive(:call)
      end

      it 'uses custom lambda' do
        subject.track_assignment(123, {})

        expect(handler).to have_received(:call).with(error)
      end
    end
  end
end
