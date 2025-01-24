require 'rails_helper'

RSpec.describe TestTrack::Client do
  describe '.fake?' do
    it 'is fake when TestTrack is not enabled' do
      allow(TestTrack).to receive(:enabled?).and_return(false)

      expect(described_class).to be_fake
    end

    it 'is not fake when TestTrack is enabled' do
      allow(TestTrack).to receive(:enabled?).and_return(true)

      expect(described_class).not_to be_fake
    end
  end

  describe '.build_connection' do
    it 'constructs a Faraday::Connection' do
      connection = described_class.build_connection(
        url: 'https://example.org',
        options: { open_timeout: 99, timeout: 42 }
      )

      expect(connection).to have_attributes(
        scheme: 'https',
        host: 'example.org',
        port: 443,
        options: have_attributes(open_timeout: 99, timeout: 42)
      )
    end
  end

  describe '.connection' do
    it 'is a Faraday::Connection' do
      expect(described_class.connection).to be_a(Faraday::Connection)
      expect(described_class.connection).to have_attributes(
        scheme: 'http',
        host: 'testtrack.dev',
        port: 80,
        options: have_attributes(open_timeout: 2, timeout: 4)
      )
    end

    shared_examples 'HTTP error' do |status, error|
      it "raises #{error} when the server returns a #{status} status code" do
        stub_request(:post, 'http://testtrack.dev/foo').to_return(status: status)
        expect { described_class.connection.post('/foo') }.to raise_error(error)
      end
    end

    include_examples 'HTTP error', 400, Faraday::BadRequestError
    include_examples 'HTTP error', 401, Faraday::UnauthorizedError
    include_examples 'HTTP error', 403, Faraday::ForbiddenError
    include_examples 'HTTP error', 404, Faraday::ResourceNotFound
    include_examples 'HTTP error', 422, Faraday::UnprocessableEntityError
    include_examples 'HTTP error', 500, TestTrack::UnrecoverableConnectivityError
    include_examples 'HTTP error', 502, TestTrack::UnrecoverableConnectivityError
    include_examples 'HTTP error', 503, TestTrack::UnrecoverableConnectivityError
    include_examples 'HTTP error', 504, TestTrack::UnrecoverableConnectivityError

    it 'raises TestTrack::UnrecoverableConnectivityError when the connection fails' do
      stub_request(:post, 'http://testtrack.dev/foo').to_raise(Faraday::ConnectionFailed)
      expect { described_class.connection.post('/foo') }.to raise_error(TestTrack::UnrecoverableConnectivityError)
    end

    it 'raises TestTrack::UnrecoverableConnectivityError when a timeout occurs' do
      stub_request(:post, 'http://testtrack.dev/foo').to_timeout
      expect { described_class.connection.post('/foo') }.to raise_error(TestTrack::UnrecoverableConnectivityError)
    end

    it 'raises status errors before attempting to parse' do
      stub_request(:post, 'http://testtrack.dev/foo').to_return(status: 500, body: '<html></html>')
      expect { described_class.connection.post('/foo') }.to raise_error(TestTrack::UnrecoverableConnectivityError)
    end
  end

  describe '.connection=' do
    around do |example|
      original_connection = described_class.connection
      example.run
    ensure
      described_class.connection = original_connection
    end

    it 'allows the connection to be reassigned' do
      new_connection = instance_double(Faraday::Connection)
      described_class.connection = new_connection
      expect(described_class.connection).to be(new_connection)
    end
  end

  describe '.request' do
    let!(:endpoint) do
      stub_request(:get, 'http://testtrack.dev/foo').to_return(status: 200, body: '{"type": "REAL"}')
    end

    let(:response) do
      described_class.request(method: :get, path: '/foo', fake: { type: 'FAKE' })
    end

    it 'executes real HTTP requests when TestTrack is enabled' do
      allow(TestTrack).to receive(:enabled?).and_return(true)

      expect(response).to eq('type' => 'REAL')
      expect(endpoint).to have_been_requested
    end

    it 'returns fake responses when TestTrack is not enabled' do
      allow(TestTrack).to receive(:enabled?).and_return(false)

      expect(response).to eq('type' => 'FAKE')
      expect(endpoint).not_to have_been_requested
    end
  end
end
