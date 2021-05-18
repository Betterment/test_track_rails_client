require 'rails_helper'

RSpec.describe TestTrack::IdentifierCreationJob do
  describe '#perform_now' do
    it 'creates an identifier' do
      allow(TestTrack::Remote::Identifier).to receive(:create!).and_call_original

      described_class.perform_now(
        identifier_type: 'myappdb_user_id',
        visitor_id: "fake_visitor_id",
        value: "444"
      )

      expect(TestTrack::Remote::Identifier).to have_received(:create!).with(
        identifier_type: 'myappdb_user_id',
        visitor_id: "fake_visitor_id",
        value: "444"
      )
    end
  end

  describe '#perform_later' do
    it 'enqueues a job and performs it' do
      allow(TestTrack::Remote::Identifier).to receive(:create!).and_call_original

      expect {
        described_class.perform_later(
          identifier_type: 'myappdb_user_id',
          visitor_id: "fake_visitor_id",
          value: "444"
        )
      }.to change { enqueued_jobs.count }.to 1

      expect(TestTrack::Remote::Identifier).not_to have_received(:create!)

      perform_enqueued_jobs do
        expect {
          described_class.perform_later(
            identifier_type: 'myappdb_user_id',
            visitor_id: "fake_visitor_id",
            value: "444"
          )
        }.to change { performed_jobs.count }.to 1
      end

      expect(TestTrack::Remote::Identifier).to have_received(:create!).with(
        identifier_type: 'myappdb_user_id',
        visitor_id: "fake_visitor_id",
        value: "444"
      )
    end
  end
end
