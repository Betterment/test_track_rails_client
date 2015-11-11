require 'rails_helper'

RSpec.describe TestTrack::ConfigUpdater do
  let(:filename) { "#{Rails.root}/db/test_track_schema.yml" }
  let(:file) { instance_double(File, read: "") }

  before do
    allow(File).to receive(:open).and_return(file)
    allow(YAML).to receive(:dump).and_return(file)
  end

  describe "#split" do
    it "updates split_config" do
      allow(TestTrack::SplitConfig).to receive(:create!).and_call_original
      expect(subject.split(:name, foo: 20, bar: 80)).to be_truthy
      expect(TestTrack::SplitConfig).to have_received(:create!).with(name: :name, weighting_registry: { foo: 20, bar: 80 })
    end

    it "persists the splits to a schema file" do
      subject.split(:name, foo: 20, bar: 80)

      expect(File).to have_received(:open).with(filename, "a+")
      expect(File).to have_received(:open).with(filename, "w")
      expect(YAML).to have_received(:dump).with({ "identifier_types" => [], "splits" => { "name" => { "foo" => 20, "bar" => 80 } } }, file)
    end

    it "does not overwrite what is currently in the schema file" do
      allow(YAML).to receive(:load).and_return(
        "identifier_types" => ["some_identifier_type"],
        "splits" => {
          "blue_button" => { "true" => 50, "false" => 50 }
        }
      )

      subject.split(:name, foo: 20, bar: 80)

      expect(YAML).to have_received(:dump).with(
        {
          "identifier_types" => ["some_identifier_type"],
          "splits" => {
            "blue_button" => { "true" => 50, "false" => 50 },
            "name" => { "foo" => 20, "bar" => 80 }
          }
        },
        file
      )
    end
  end

  describe "#identifier_type" do
    it "updates identifier_type" do
      allow(TestTrack::IdentifierType).to receive(:create!).and_call_original
      expect(subject.identifier_type(:my_id)).to be_truthy
      expect(TestTrack::IdentifierType).to have_received(:create!).with(name: :my_id)
    end

    it "persists the identifier types to a schema file" do
      subject.identifier_type(:my_id)

      expect(File).to have_received(:open).with(filename, "a+")
      expect(File).to have_received(:open).with(filename, "w")
      expect(YAML).to have_received(:dump).with({ "identifier_types" => ["my_id"], "splits" => {} }, file)
    end

    it "does not overwrite what is currently in the schema file" do
      allow(YAML).to receive(:load).and_return(
        "identifier_types" => ["some_identifier_type"],
        "splits" => {
          "blue_button" => { "true" => 50, "false" => 50 }
        }
      )

      subject.identifier_type(:my_id)

      expect(YAML).to have_received(:dump).with(
        {
          "identifier_types" => %w(some_identifier_type my_id),
          "splits" => {
            "blue_button" => { "true" => 50, "false" => 50 }
          }
        },
        file
      )
    end
  end
end
