require 'rails_helper'

RSpec.describe TestTrack::Remote::Visitor do
  before do
    stub_request(:get, url)
      .with(basic_auth: %w(dummy fakepassword))
      .to_return(status: 200, body: {
        id: "fake_visitor_id_from_server",
        assignments: [
          { split_name: "time", variant: "clownin_around", unsynced: true, context: "the_context" }
        ]
      }.to_json)
  end

  describe ".find" do
    let(:url) { "http://testtrack.dev/api/v1/visitors/fake_visitor_id_from_server" }

    subject { described_class.find("fake_visitor_id_from_server") }

    it "instantiates a Visitor with fake instance attributes" do
      expect(subject.id).to eq("fake_visitor_id")
      subject.assignments.first.tap do |assignment|
        expect(assignment.split_name).to eq("split_1")
        expect(assignment.variant).to eq("true")
        expect(assignment.context).to eq("context")
        expect(assignment).not_to be_unsynced
      end
    end

    it "fetches attributes from the test track server when enabled" do
      with_test_track_enabled do
        expect(subject.id).to eq("fake_visitor_id_from_server")
        subject.assignments.first.tap do |assignment|
          expect(assignment.split_name).to eq("time")
          expect(assignment.variant).to eq("clownin_around")
          expect(assignment.context).to eq("the_context")
          expect(assignment).to be_unsynced
        end
      end
    end

    context 'when TestTrack is mounted at a path' do
      let(:url) { "http://someapp.test/tt/api/v1/visitors/fake_visitor_id_from_server" }
      let(:fake_api) do
        Her::API.new.setup url: 'http://dummy:fakepassword@someapp.test/tt' do |c|
          c.request :json
          c.use TestTrack::ServerErrorMiddleware
          c.use Her::Middleware::DefaultParseJSON
          c.adapter Faraday.default_adapter
        end
      end

      around do |example|
        TestTrack::Remote::Visitor.use_api fake_api
        example.run
      ensure
        TestTrack::Remote::Visitor.use_api TestTrack::TestTrackApi
      end

      it "fetches attributes from the test track server" do
        with_test_track_enabled do
          expect(subject.id).to eq("fake_visitor_id_from_server")
          subject.assignments.first.tap do |assignment|
            expect(assignment.split_name).to eq("time")
            expect(assignment.variant).to eq("clownin_around")
            expect(assignment.context).to eq("the_context")
            expect(assignment).to be_unsynced
          end
        end
      end
    end
  end

  describe ".from_identifier" do
    subject { described_class.from_identifier("clown_id", "1234") }
    let(:url) { "http://testtrack.dev/api/v1/identifier_types/clown_id/identifiers/1234/visitor" }

    it "raises when given a blank identifier_type" do
      expect { TestTrack::Remote::Visitor.from_identifier("", "1234") }
        .to raise_error("must provide an identifier_type")
    end

    it "raises when given a blank identifier_value" do
      expect { TestTrack::Remote::Visitor.from_identifier("clown_id", "") }
        .to raise_error("must provide an identifier_value")
    end

    it "instantiates a Visitor with fake instance attributes" do
      expect(subject.id).to eq("fake_visitor_id")
      subject.assignments.first.tap do |assignment|
        expect(assignment.split_name).to eq("split_1")
        expect(assignment.variant).to eq("true")
        expect(assignment.context).to eq("context")
        expect(assignment.unsynced).to eq(false)
      end
    end

    it "fetches attributes from the test track server when enabled" do
      with_test_track_enabled do
        expect(subject.id).to eq("fake_visitor_id_from_server")
        subject.assignments.first.tap do |assignment|
          expect(assignment.split_name).to eq("time")
          expect(assignment.variant).to eq("clownin_around")
          expect(assignment.context).to eq("the_context")
          expect(assignment.unsynced).to eq(true)
        end
      end
    end
  end
end
