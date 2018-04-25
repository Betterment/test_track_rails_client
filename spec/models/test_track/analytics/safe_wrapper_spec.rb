require 'rails_helper'

RSpec.describe TestTrack::Analytics::SafeWrapper do
  let(:underlying) { double("Client", track: true, sign_up!: true) }

  subject { TestTrack::Analytics::SafeWrapper.new(underlying) }

  describe '#track' do
    it 'calls underlying' do
      expect(subject.track("my event")).to eq true
      expect(underlying).to have_received(:track).with("my event")
    end

    context 'underlying raises' do
      it 'returns false' do
        allow(underlying).to receive(:track).and_raise StandardError

        expect(subject.track("my event")).to eq false
        expect(underlying).to have_received(:track).with("my event")
      end
    end
  end

  describe '#sign_up!' do
    context 'when client does not implement sign_up! method' do
      let(:underlying) { double("Client", respond_to?: false) }

      it 'does not call sign_up! on analytics client' do
        expect(underlying).not_to receive(:sign_up!)
        subject.sign_up!(1)
      end
    end

    context 'when client does implement sign_up! method' do
      it 'calls sign_up! on analytics client' do
        expect(underlying).to receive(:sign_up!)
        subject.sign_up!(1)
      end

      context 'when sign_up! method does not accept one argument' do
        class TestClient
          def sign_up!(visitor_id, extraneous_arg); end
        end
        let(:underlying) { TestClient.new }

        it 'logs an argument error' do
          expect(Rails.logger).to receive(:error).with(ArgumentError)
          subject.sign_up!(1)
        end
      end
    end
  end

  describe 'error handling' do
    let(:error) { StandardError.new("Something went wrong") }

    before do
      allow(underlying).to receive(:track).and_raise error
      allow(Rails.logger).to receive(:error)
    end

    it 'logs error to Rails.logger' do
      subject.track("my event")

      expect(Rails.logger).to have_received(:error).with(error)
    end

    context 'when custom lambda provided' do
      let(:handler) { ->(_) { nil } }

      before do
        subject.error_handler = handler

        allow(handler).to receive(:call)
      end

      it 'uses custom lambda' do
        subject.track("my event")

        expect(handler).to have_received(:call).with(error)
      end
    end
  end
end
