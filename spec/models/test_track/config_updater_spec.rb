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
        expect_schema <<-YML
---
identifier_types: []
splits:
  name:
    bar: 80
    foo: 20
YML
      end

      it "does not overwrite existing splits" do
        given_schema <<-YML
---
identifier_types:
- some_identifier_type
splits:
  red_button:
    'false': 50
    'true': 50
YML

        subject.split(:name, foo: 20, bar: 80)

        expect_schema <<-YML
---
identifier_types:
- some_identifier_type
splits:
  name:
    bar: 80
    foo: 20
  red_button:
    'false': 50
    'true': 50
YML
      end

      it "deletes splits that are no longer on the test track server" do
        given_schema <<-YML
---
identifier_types:
- some_identifier_type
splits:
  blue_button:
    'false': 50
    'true': 50
  really_old_split:
    'false': 50
    'true': 50
YML

        allow(TestTrack::SplitRegistry).to receive(:reset).and_call_original
        allow(TestTrack::SplitRegistry).to receive(:to_hash).and_return(
          "blue_button" => { "true" => 50, "false" => 50 },
          "split_for_another_app" => { "true" => 50, "false" => 50 }
        )

        subject.split(:name, foo: 20, bar: 80)

        expect(TestTrack::SplitRegistry).to have_received(:reset)
        expect_schema <<-YML
---
identifier_types:
- some_identifier_type
splits:
  blue_button:
    'false': 50
    'true': 50
  name:
    bar: 80
    foo: 20
YML
      end

      it "alphabetizes the splits and the weighting registries" do
        given_schema <<-YML
---
identifier_types: []
splits:
  a:
    'false': 50
    'true': 50
  b:
    'false': 50
    'true': 50
  d:
    'false': 50
    'true': 50
YML

        subject.split(:c, true: 50, false: 50)

        expect_schema <<-YML
---
identifier_types: []
splits:
  a:
    'false': 50
    'true': 50
  b:
    'false': 50
    'true': 50
  c:
    'false': 50
    'true': 50
  d:
    'false': 50
    'true': 50
YML
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

        expect_schema <<-YML
---
identifier_types:
- my_id
splits: {}
YML
      end

      it "alphabetizes the identifier types" do
        subject.identifier_type(:b)
        subject.identifier_type(:a)
        subject.identifier_type(:d)
        subject.identifier_type(:c)

        expect_schema <<-YML
---
identifier_types:
- a
- b
- c
- d
splits: {}
YML
      end

      it "does not overwrite existing identifier types" do
        given_schema <<-YML
---
identifier_types:
- some_identifier_type
splits:
  blue_button:
    'false': 50
    'true': 50
YML

        subject.identifier_type(:my_id)

        expect_schema <<-YML
---
identifier_types:
- my_id
- some_identifier_type
splits:
  blue_button:
    'false': 50
    'true': 50
YML
      end
    end
  end

  describe "#load_schema" do
    it "updates the split_config and identifier_types" do
      allow(TestTrack::SplitConfig).to receive(:create!).and_call_original
      allow(TestTrack::IdentifierType).to receive(:create!).and_call_original

      given_schema <<-YML
---
identifier_types:
- a
- b
- c
splits:
  balance_unit:
    dollar: 50
    pound: 25
    doge: 25
  blue_button:
    'false': 50
    'true': 50
YML

      subject.load_schema

      expect(TestTrack::SplitConfig).to have_received(:create!).with(
        name: "balance_unit",
        weighting_registry: { "dollar" => 50, "pound" => 25, "doge" => 25 }
      )
      expect(TestTrack::SplitConfig).to have_received(:create!).with(
        name: "blue_button",
        weighting_registry: { "true" => 50, "false" => 50 }
      )
      expect(TestTrack::IdentifierType).to have_received(:create!).with(name: "a")
      expect(TestTrack::IdentifierType).to have_received(:create!).with(name: "b")
      expect(TestTrack::IdentifierType).to have_received(:create!).with(name: "c")

      expect_schema <<-YML
---
identifier_types:
- a
- b
- c
splits:
  balance_unit:
    dollar: 50
    pound: 25
    doge: 25
  blue_button:
    'false': 50
    'true': 50
YML
    end
  end

  def given_schema(yaml)
    File.open(schema_file_path, "w") do |f|
      f.write yaml
    end
    allow(TestTrack::SplitRegistry).to receive(:to_hash).and_return(YAML.load(yaml)["splits"])
  end

  def expect_schema(yaml)
    File.open(schema_file_path, "r") do |f|
      expect(f.read).to eq yaml
    end
  end
end
