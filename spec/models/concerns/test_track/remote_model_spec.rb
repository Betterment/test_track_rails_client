require 'rails_helper'

RSpec.describe TestTrack::Identity do
  context 'handling server timeouts' do
    describe 'for get requests' do
      before do
        stub_request(:get, 'http://testtrack.dev/api/v1/remotes/fake_id').to_timeout
      end

      it 'reraises them as TestTrack::UnrecoverableConnectivityError' do
        with_test_track_enabled do
          expect { Remote.find('fake_id') }.to raise_error(TestTrack::UnrecoverableConnectivityError)
        end
      end
    end

    describe 'for post requests' do
      before do
        stub_request(:post, 'http://testtrack.dev/api/v1/remotes').to_timeout
      end

      it 'reraises them as TestTrack::UnrecoverableConnectivityError' do
        with_test_track_enabled do
          expect { Remote.new.save }.to raise_error(TestTrack::UnrecoverableConnectivityError)
        end
      end
    end
  end
end
