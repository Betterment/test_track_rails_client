require 'rails_helper'

RSpec.describe TestTrack::Remote::SplitRegistry do
  let(:split_registry) do
    {
      'splits' => {
        'time' => {
          'weights' => {
            'back_in_time' => 100,
            'power_of_love' => 0
          },
          'feature_gate' => false
        }
      },
      'experience_sampling_weight' => 1
    }
  end

  before do
    allow(described_class).to receive(:instance).and_call_original
    allow(described_class).to receive(:fake_instance_attributes).and_return(split_registry)

    begin
      Rails.cache.clear
    rescue Errno::ENOENT
      # This is fine
    end
  end

  describe "#to_hash" do
    context 'with api enabled' do
      let(:url) { "http://testtrack.dev/api/v3/builds/#{TestTrack.build_timestamp}/split_registry" }
      around do |example|
        with_test_track_enabled do
          stub_request(:get, url)
            .with(basic_auth: %w(dummy fakepassword))
            .to_return(status: 200, body: {
              splits: {
                time: {
                  weights: {
                    back_in_time: 100,
                    power_of_love: 0
                  },
                  feature_gate: false
                }
              },
              experience_sampling_weight: 1
            }.to_json)
          example.run
        end
      end

      it "only hits the API once" do
        2.times { expect(described_class.to_hash).to eq(split_registry) }
        expect(described_class).to have_received(:instance).exactly(:once)
      end

      it "freezes the returned hash even when retrieving from cache" do
        2.times { expect { described_class.to_hash[:foo] = "bar" }.to raise_error(/frozen/) }
      end
    end

    it "returns nil if the server times out" do
      allow(described_class).to receive(:instance) { raise(Faraday::TimeoutError, "too slow!") }

      expect(described_class.to_hash).to eq(nil)

      expect(described_class).to have_received(:instance)
    end

    it "returns nil if the server 503s" do
      allow(described_class).to receive(:instance) { raise(Faraday::ServerError, "503 is happening") }

      expect(described_class.to_hash).to eq(nil)

      expect(described_class).to have_received(:instance)
    end
  end

  describe ".instance" do
    subject { described_class.instance }
    let(:url) { "http://testtrack.dev/api/v3/builds/#{TestTrack.build_timestamp}/split_registry" }

    before do
      stub_request(:get, url)
        .with(basic_auth: %w(dummy fakepassword))
        .to_return(status: 200, body: {
          splits: {
            remote_split: {
              weights: { variant1: 50, variant2: 50 },
              feature_gate: false
            }
          },
          experience_sampling_weight: 1
        }.to_json)
    end

    it "instantiates a SplitRegistry with fake instance attributes" do
      expect(subject.attributes).to eq(
        'splits' => {
          'time' => {
            'weights' => {
              'back_in_time' => 100, 'power_of_love' => 0
            },
            'feature_gate' => false
          }
        },
        'experience_sampling_weight' => 1
      )
    end

    it "it fetches attributes from the test track server when enabled" do
      with_test_track_enabled do
        expect(subject.attributes).to eq(
          "splits" => {
            "remote_split" => {
              "weights" => { "variant1" => 50, "variant2" => 50 },
              "feature_gate" => false
            }
          },
          "experience_sampling_weight" => 1
        )
      end
    end
  end
end
