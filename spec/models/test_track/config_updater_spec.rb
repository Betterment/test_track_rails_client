require 'rails_helper'

RSpec.describe TestTrack::ConfigUpdater do
  let(:schema_file_path) { Rails.root.join('tmp', 'test_track_schema.yml') }
  let(:errors) { double(full_messages: ["this is wrong"]) }

  subject { described_class.new(schema_file_path) }

  before do
    File.delete(schema_file_path) if File.exist?(schema_file_path)
  end

  describe "#drop_split" do
    it "destroys the split config" do
      allow(TestTrack::Remote::SplitConfig).to receive(:destroy_existing).and_call_original
      expect(subject.drop_split(:old_split)).to be_truthy
      expect(TestTrack::Remote::SplitConfig).to have_received(:destroy_existing).with(:old_split)
    end

    context "schema file" do
      it "removes the split from the schema file" do
        given_schema <<-YML.strip_heredoc
          ---
          identifier_types: []
          splits:
            old_split:
              'false': 50
              'true': 50
        YML

        subject.drop_split(:old_split)

        expect_schema <<-YML.strip_heredoc
          ---
          identifier_types: []
          splits: {}
        YML
      end
    end

    context "aliased as #finish_split" do
      it "destroys the split config" do
        allow(TestTrack::Remote::SplitConfig).to receive(:destroy_existing).and_call_original
        expect(subject.finish_split(:old_split)).to be_truthy
        expect(TestTrack::Remote::SplitConfig).to have_received(:destroy_existing).with(:old_split)
      end
    end
  end

  describe "#split" do
    let(:split_config) { instance_double(TestTrack::Remote::SplitConfig, save: true) }
    let(:invalid_split_config) { instance_double(TestTrack::Remote::SplitConfig, save: false, errors: errors) }

    it "updates split_config" do
      allow(TestTrack::Remote::SplitConfig).to receive(:new).and_call_original
      expect(subject.split(:name, foo: 20, bar: 80)).to be_truthy
      expect(TestTrack::Remote::SplitConfig).to have_received(:new).with(name: :name, weighting_registry: { foo: 20, bar: 80 })
    end

    it "calls save on the split" do
      allow(TestTrack::Remote::SplitConfig).to receive(:new).and_return(split_config)
      expect(subject.split(:name, foo: 20, bar: 80)).to be_truthy
      expect(split_config).to have_received(:save)
    end

    it "blows up if the split doesn't save" do
      allow(TestTrack::Remote::SplitConfig).to receive(:new).and_return(invalid_split_config)
      expect { subject.split(:name, foo: 20, bar: 80) }.to raise_error(/this is wrong/)
    end

    context "schema file" do
      it "persists the splits" do
        subject.split(:name, foo: 20, bar: 80)
        expect_schema <<-YML.strip_heredoc
          ---
          identifier_types: []
          splits:
            name:
              bar: 80
              foo: 20
        YML
      end

      it "persists multiple splits" do
        subject.split(:name, foo: 20, bar: 80)
        subject.split(:gnome, baz: 30, bop: 70)
        subject.split(:nom, wibble: 40, wobble: 60)
        expect_schema <<-YML.strip_heredoc
          ---
          identifier_types: []
          splits:
            gnome:
              baz: 30
              bop: 70
            name:
              bar: 80
              foo: 20
            nom:
              wibble: 40
              wobble: 60
        YML
      end

      it "does not overwrite existing splits" do
        given_schema <<-YML.strip_heredoc
          ---
          identifier_types:
          - some_identifier_type
          splits:
            red_button:
              'false': 50
              'true': 50
        YML

        subject.split(:name, foo: 20, bar: 80)

        expect_schema <<-YML.strip_heredoc
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
        given_schema <<-YML.strip_heredoc
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

        allow(TestTrack::Remote::SplitRegistry).to receive(:reset).and_call_original
        allow(TestTrack::Remote::SplitRegistry).to receive(:to_hash).and_return(
          "blue_button" => { "true" => 50, "false" => 50 },
          "split_for_another_app" => { "true" => 50, "false" => 50 }
        )

        subject.split(:name, foo: 20, bar: 80)

        expect(TestTrack::Remote::SplitRegistry).to have_received(:reset)
        expect_schema <<-YML.strip_heredoc
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
        given_schema <<-YML.strip_heredoc
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

        expect_schema <<-YML.strip_heredoc
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
    let(:identifier_type) { instance_double(TestTrack::Remote::IdentifierType, save: true) }
    let(:invalid_identifier_type) { instance_double(TestTrack::Remote::IdentifierType, save: false, errors: errors) }

    it "updates identifier_type" do
      allow(TestTrack::Remote::IdentifierType).to receive(:new).and_call_original
      expect(subject.identifier_type(:my_id)).to be_truthy
      expect(TestTrack::Remote::IdentifierType).to have_received(:new).with(name: :my_id)
    end

    it "calls save on the identifier_type" do
      allow(TestTrack::Remote::IdentifierType).to receive(:new).and_return(identifier_type)
      expect(subject.identifier_type(:my_id)).to be_truthy
      expect(identifier_type).to have_received(:save)
    end

    it "blows up if the identifier_type doesn't save" do
      allow(TestTrack::Remote::IdentifierType).to receive(:new).and_return(invalid_identifier_type)
      expect { subject.identifier_type(:my_id) }.to raise_error(/this is wrong/)
    end

    context "schema file" do
      it "persists the identifier types" do
        subject.identifier_type(:my_id)

        expect_schema <<-YML.strip_heredoc
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

        expect_schema <<-YML.strip_heredoc
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
        given_schema <<-YML.strip_heredoc
          ---
          identifier_types:
          - some_identifier_type
          splits:
            blue_button:
              'false': 50
              'true': 50
        YML

        subject.identifier_type(:my_id)

        expect_schema <<-YML.strip_heredoc
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
      allow(TestTrack::Remote::SplitConfig).to receive(:new).and_call_original
      allow(TestTrack::Remote::IdentifierType).to receive(:new).and_call_original

      given_schema <<-YML.strip_heredoc
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

      expect(TestTrack::Remote::SplitConfig).to have_received(:new).with(
        name: "balance_unit",
        weighting_registry: { "dollar" => 50, "pound" => 25, "doge" => 25 }
      )
      expect(TestTrack::Remote::SplitConfig).to have_received(:new).with(
        name: "blue_button",
        weighting_registry: { "true" => 50, "false" => 50 }
      )
      expect(TestTrack::Remote::IdentifierType).to have_received(:new).with(name: "a")
      expect(TestTrack::Remote::IdentifierType).to have_received(:new).with(name: "b")
      expect(TestTrack::Remote::IdentifierType).to have_received(:new).with(name: "c")

      expect_schema <<-YML.strip_heredoc
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
    allow(TestTrack::Remote::SplitRegistry).to receive(:to_hash).and_return(YAML.safe_load(yaml)["splits"])
  end

  def expect_schema(yaml)
    File.open(schema_file_path, "r") do |f|
      expect(f.read).to eq yaml
    end
  end
end
