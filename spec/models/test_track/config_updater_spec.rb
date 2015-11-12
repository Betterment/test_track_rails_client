require 'rails_helper'

RSpec.describe TestTrack::ConfigUpdater do
  let(:schema_file_path) { "#{Rails.root}/tmp/test_track_schema.yml" }

  subject { described_class.new(schema_file_path) }

  before do
    File.delete schema_file_path
  end

  describe "#split" do
    it "updates split_config" do
      allow(TestTrack::SplitConfig).to receive(:create!).and_call_original
      expect(subject.split(:name, foo: 20, bar: 80)).to be_truthy
      expect(TestTrack::SplitConfig).to have_received(:create!).with(name: :name, weighting_registry: { foo: 20, bar: 80 })
    end

    context "schema file" do
      it "persists the splits" do
        subject.split(:name, foo: 20, bar: 80)
        expect_schema "identifier_types" => [], "splits" => { "name" => { "foo" => 20, "bar" => 80 } }
      end

      it "does not overwrite existing splits" do
        given_schema(
          "identifier_types" => ["some_identifier_type"],
          "splits" => {
            "blue_button" => { "true" => 50, "false" => 50 }
          }
        )

        subject.split(:name, foo: 20, bar: 80)

        expect_schema(
          "identifier_types" => ["some_identifier_type"],
          "splits" => {
            "blue_button" => { "true" => 50, "false" => 50 },
            "name" => { "foo" => 20, "bar" => 80 }
          }
        )
      end

      it "deletes splits that are no longer on the test track server" do
        given_schema(
          "identifier_types" => ["some_identifier_type"],
          "splits" => {
            "really_old_split" => { "true" => 50, "false" => 50 },
            "blue_button" => { "true" => 50, "false" => 50 }
          }
        )

        allow(TestTrack::SplitRegistry).to receive(:to_hash).and_return(
          "split_for_another_app" => { "true" => 50, "false" => 50 },
          "blue_button" => { "true" => 50, "false" => 50 }
        )

        subject.split(:name, foo: 20, bar: 80)

        expect_schema(
          "identifier_types" => ["some_identifier_type"],
          "splits" => {
            "blue_button" => { "true" => 50, "false" => 50 },
            "name" => { "foo" => 20, "bar" => 80 }
          }
        )
      end
    end
  end

  describe "#identifier_type" do
    it "updates identifier_type" do
      allow(TestTrack::IdentifierType).to receive(:create!).and_call_original
      expect(subject.identifier_type(:my_id)).to be_truthy
      expect(TestTrack::IdentifierType).to have_received(:create!).with(name: :my_id)
    end

    context "schema file" do
      it "persists the identifier types" do
        subject.identifier_type(:my_id)

        expect_schema "identifier_types" => ["my_id"], "splits" => {}
      end

      it "alphabetizes the identifier types" do
        subject.identifier_type(:b)
        subject.identifier_type(:a)
        subject.identifier_type(:d)
        subject.identifier_type(:c)

        expect_schema "identifier_types" => %w(a b c d), "splits" => {}
      end

      it "does not overwrite existing identifier types" do
        given_schema(
          "identifier_types" => ["some_identifier_type"],
          "splits" => {
            "blue_button" => { "true" => 50, "false" => 50 }
          }
        )

        subject.identifier_type(:my_id)

        expect_schema(
          "identifier_types" => %w(my_id some_identifier_type),
          "splits" => {
            "blue_button" => { "true" => 50, "false" => 50 }
          }
        )
      end
    end
  end

  describe "#load_schema" do
    it "updates the split_config and identifier_types" do
      allow(TestTrack::SplitConfig).to receive(:create!).and_call_original
      allow(TestTrack::IdentifierType).to receive(:create!).and_call_original

      given_schema(
        "identifier_types" => %w(one two three),
        "splits" => {
          "blue_button" => { "true" => 50, "false" => 50 },
          "balance_unit" => { "dollar" => 50, "pound" => 25, "doge" => 25 }
        }
      )

      subject.load_schema

      expect(TestTrack::SplitConfig).to have_received(:create!).with(name: "blue_button", weighting_registry: { "true" => 50, "false" => 50 })
      expect(TestTrack::SplitConfig).to have_received(:create!).with(name: "balance_unit", weighting_registry: { "dollar" => 50, "pound" => 25, "doge" => 25 })
      expect(TestTrack::IdentifierType).to have_received(:create!).with(name: "one")
      expect(TestTrack::IdentifierType).to have_received(:create!).with(name: "two")
      expect(TestTrack::IdentifierType).to have_received(:create!).with(name: "three")

      expect_schema(
        "identifier_types" => %w(one two three),
        "splits" => {
          "blue_button" => { "true" => 50, "false" => 50 },
          "balance_unit" => { "dollar" => 50, "pound" => 25, "doge" => 25 }
        }
      )
    end
  end

  def given_schema(hash)
    File.open(schema_file_path, "w") do |f|
      f.write YAML.dump(hash)
    end
  end

  def expect_schema(hash)
    File.open(schema_file_path, "r") do |f|
      expect(YAML.load(f.read)).to eq hash
    end
  end
end
