require 'rails_helper'

RSpec.describe TestTrack::IdentitySessionLocator do
  let(:identity) { Clown.new(id: 1234) }

  subject { described_class.new(identity) }

  describe "#with_visitor" do
    it "raises without a provided block" do
      expect { subject.with_visitor }.to raise_exception /must provide block to `with_visitor`/
    end

    context "within a web session" do
      let(:test_track_session) { instance_double(TestTrack::WebSession) }
      let(:visitor_dsl) { instance_double(TestTrack::VisitorDSL) }

      before do
        allow(RequestStore).to receive(:[]).with(:test_track_web_session).and_return(test_track_session)
        allow(test_track_session).to receive(:visitor_dsl_for).and_return(visitor_dsl)
      end

      it "yields the session's visitor dsl" do
        subject.with_visitor do |visitor|
          expect(visitor).to eq visitor_dsl
        end
      end
    end

    context 'within a job session' do
      let(:test_track_session) { instance_double(TestTrack::JobSession) }
      let(:visitor_dsl) { instance_double(TestTrack::VisitorDSL) }

      before do
        allow(RequestStore).to receive(:[]).with(:test_track_web_session).and_return(nil)
        allow(RequestStore).to receive(:[]).with(:test_track_job_session).and_return(test_track_session)
        allow(test_track_session).to receive(:visitor_dsl_for).and_return(visitor_dsl)
      end

      it "yields the session's visitor dsl" do
        subject.with_visitor do |visitor|
          expect(visitor).to eq visitor_dsl
        end
      end
    end

    context "outside of any session" do
      let(:visitor_dsl) { instance_double(TestTrack::VisitorDSL) }

      before do
        allow(TestTrack::OfflineSession).to receive(:with_visitor_for).and_yield(visitor_dsl)
      end

      it "creates an offline session and yields its visitor" do
        subject.with_visitor do |visitor|
          expect(visitor).to eq visitor_dsl
        end

        expect(TestTrack::OfflineSession).to have_received(:with_visitor_for).with("clown_id", 1234)
      end
    end
  end

  describe "#with_session" do
    it "raises without a provided block" do
      expect { subject.with_session }.to raise_exception /must provide block to `with_session`/
    end

    context "within a web session" do
      let(:test_track_session) { instance_double(TestTrack::WebSession) }

      before do
        allow(RequestStore).to receive(:[]).with(:test_track_web_session).and_return(test_track_session)
      end

      it "yields the session" do
        subject.with_session do |session|
          expect(session).to eq test_track_session
        end
      end
    end

    context 'within a job session' do
      let(:test_track_session) { instance_double(TestTrack::JobSession) }

      before do
        allow(RequestStore).to receive(:[]).with(:test_track_web_session).and_return(nil)
        allow(RequestStore).to receive(:[]).with(:test_track_job_session).and_return(test_track_session)
      end

      it "raises" do
        expect { subject.with_session {} }.to raise_exception /#with_session called outside of web session/
      end
    end

    context "outside of any session" do
      it "raises" do
        expect { subject.with_session {} }.to raise_exception /#with_session called outside of web session/
      end
    end
  end
end
