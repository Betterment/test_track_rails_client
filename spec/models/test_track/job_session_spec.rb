require 'rails_helper'

RSpec.describe TestTrack::JobSession do
  subject { described_class.new }

  let(:clown) { Clown.new(id: 1234) }

  describe '#manage' do
    it 'requires a block' do
      expect { subject.manage }.to raise_error 'must provide block to `manage`'
    end

    it 'maintains itself in the request store' do
      expect(RequestStore[:test_track_job_session]).to be_nil

      subject.manage do
        expect(RequestStore[:test_track_job_session]).to eq subject

        inner_session = described_class.new
        inner_session.manage do
          expect(RequestStore[:test_track_job_session]).to eq inner_session
        end
        expect(RequestStore[:test_track_job_session]).to eq subject
      end

      expect(RequestStore[:test_track_job_session]).to be_nil
    end

    context 'assignment notification' do
      let(:visitor_notifier) { instance_double(TestTrack::ThreadedVisitorNotifier, notify: true) }

      before do
        allow(TestTrack::ThreadedVisitorNotifier).to receive(:new).and_return(visitor_notifier)
      end

      it 'notifies unsynced assignments' do
        subject.manage do
          clown.test_track_ab(:buy_one_get_one_promotion_enabled, context: 'spec')
        end

        expect(visitor_notifier).to have_received(:notify)
      end

      it 'does not notify with no unsynced assignments' do
        subject.manage do
          clown.test_track_visitor_id
        end

        expect(TestTrack::ThreadedVisitorNotifier).not_to have_received(:new)
      end
    end
  end

  describe '#visitor_dsl_for' do
    let(:remote_visitor) { instance_double(TestTrack::Remote::Visitor, id: 'fake_visitor_id', assignments: {}) }

    before do
      allow(TestTrack::Remote::Visitor).to receive(:from_identifier).and_return(remote_visitor)
    end

    it 'raises if called outside `manage` block' do
      expect { subject.visitor_dsl_for(clown) }.to raise_error 'must be called within `manage` block'
    end

    it 'returns a visitor dsl from a store of remote visitors' do
      subject.manage do
        expect(subject.visitor_dsl_for(clown)).to be_a(TestTrack::VisitorDSL)

        subject.visitor_dsl_for(clown).ab(:buy_one_get_one_promotion_enabled, context: 'spec')
        subject.visitor_dsl_for(clown).ab(:buy_one_get_one_promotion_enabled, context: 'spec')
      end

      expect(TestTrack::Remote::Visitor).to have_received(:from_identifier).with('clown_id', 1234).once
    end
  end
end
