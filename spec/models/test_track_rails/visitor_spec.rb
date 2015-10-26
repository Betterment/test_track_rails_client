require 'rails_helper'

RSpec.describe TestTrackRails::Visitor do
  let(:new_visitor) { described_class.new }
  let(:existing_visitor) { described_class.new(id: existing_visitor_id) }
  let(:existing_visitor_id) { "00000000-0000-0000-0000-000000000000" }
  let(:assignment_registry) { { 'blue_button' => 'true' } }
  let(:split_registry) do
    {
      'blue_button' => {
        'false' => 50,
        'true' => 50
      },
      'quagmire' => {
        'untenable' => 50,
        'manageable' => 50
      }
    }
  end

  before do
    allow(TestTrackRails::AssignmentRegistry).to receive(:for_visitor).and_call_original
    allow(TestTrackRails::AssignmentRegistry).to receive(:fake_instance_attributes).and_return(assignment_registry)
    allow(TestTrackRails::SplitRegistry).to receive(:to_hash).and_return(split_registry)
  end

  it "preserves a passed ID" do
    expect(existing_visitor.id).to eq existing_visitor_id
  end

  it "generates its own UUID otherwise" do
    allow(SecureRandom).to receive(:uuid).and_return("fake uuid")
    expect(new_visitor.id).to eq "fake uuid"
  end

  describe "#assignment_registry" do
    it "doesn't request the registry for a newly-generated visitor" do
      expect(new_visitor.assignment_registry).to eq({})
      expect(TestTrackRails::AssignmentRegistry).not_to have_received(:for_visitor)
    end

    it "returns the server-provided assignments for an existing visitor" do
      expect(existing_visitor.assignment_registry).to eq assignment_registry
    end
  end

  describe "#new_assignments" do
    it "doesn't include a server-provided assignment, even if requested" do
      expect(existing_visitor.assignment_for('blue_button')).to eq(true)

      expect(existing_visitor.new_assignments).not_to have_key('blue_button')
    end
  end

  describe "#vary" do
    let(:blue_block) { ->{ '.blue' } }
    let(:red_block) { ->{ '.red' } }

    let(:win_block) { ->{ '#win' } }
    let(:fail_block) { ->{ '#fail' } }

    before do
      allow(TestTrackRails::VariantCalculator).to receive(:new).and_return(double(variant: 'untenable'))
    end

    it "branches with existing assignment" do
      expect(
        existing_visitor.vary(:blue_button) do |v|
          v.when :true, &blue_block
          v.default :false, &red_block
        end
      ).to eq '.blue'
    end

    it "branches with brand new assignment" do
      expect(
        new_visitor.vary(:quagmire) do |v|
          v.when :untenable, &fail_block
          v.default :manageable, &win_block
        end
      ).to eq '#fail'
    end

    context "structure" do
      it "must be given a block" do
        expect { new_visitor.vary(:blue_button) }.to raise_error("must provide block to `vary` for blue_button")
      end

      it "requires less than two defaults" do
        expect {
          new_visitor.vary(:blue_button) do |v|
            v.when :true, &blue_block
            v.default :false, &red_block
            v.default :false, &red_block
          end
        }.to raise_error("cannot provide more than one `default`")
      end

      it "requires more than zero defaults" do
        expect { new_visitor.vary(:blue_button) { |v| v.when(:true, &blue_block) } }.to raise_error("must provide exactly one `default`")
      end

      it "requires at least one when" do
        expect {
          new_visitor.vary(:blue_button) do |v|
            v.default :true, &red_block
          end
        }.to raise_error("must provide at least one `when`")
      end
    end

  end


  describe "#assignment_for" do
    before do
      allow(TestTrackRails::VariantCalculator).to receive(:new).and_return(double(variant: 'untenable'))
    end

    it "returns an existing assignment without generating" do
      expect(existing_visitor.assignment_for('blue_button')).to eq(true)

      expect(TestTrackRails::VariantCalculator).not_to have_received(:new)
    end

    it "assigns a new split via VariantCalculator" do
      expect(existing_visitor.assignment_for('quagmire')).to eq('untenable')

      expect(TestTrackRails::VariantCalculator).to have_received(:new).with(visitor: existing_visitor, split_name: 'quagmire')
    end

    it "adds new assignments to new_assignments" do
      expect(existing_visitor.assignment_for('quagmire')).to eq('untenable')

      expect(existing_visitor.new_assignments['quagmire']).to eq 'untenable'
    end

    it "adds new assigments to assignment_registry" do
      expect(existing_visitor.assignment_for('quagmire')).to eq('untenable')

      expect(existing_visitor.assignment_registry['quagmire']).to eq 'untenable'
    end
  end

  describe "#split_registry" do
    it "memoizes the global SplitRegistry hash" do
      2.times { existing_visitor.split_registry }
      expect(TestTrackRails::SplitRegistry).to have_received(:to_hash).exactly(:once)
    end
  end

  describe "#log_in!" do
    let(:delayed_identifier_proxy) { double(create!: "fake visitor") }

    before do
      allow(TestTrackRails::Identifier).to receive(:delay).and_return(delayed_identifier_proxy)
    end

    it "sends the appropriate params to test track" do
      allow(TestTrackRails::Identifier).to receive(:create!).and_call_original
      existing_visitor.log_in!('bettermentdb_user_id', 444)
      expect(TestTrackRails::Identifier).to have_received(:create!).with(
        identifier_type: 'bettermentdb_user_id',
        visitor_id: existing_visitor_id,
        value: "444"
      )
    end

    it "preserves id if unchanged" do
      expect(existing_visitor.log_in!('bettermentdb_user_id', 444).id).to eq existing_visitor_id
    end

    it "delays the identifier creation if TestTrack times out and carries on" do
      allow(TestTrackRails::Identifier).to receive(:create!) { raise(Faraday::TimeoutError, "You snooze you lose!") }

      expect(existing_visitor.log_in!('bettermentdb_user_id', 444).id).to eq existing_visitor_id

      expect(delayed_identifier_proxy).to have_received(:create!).with(
        identifier_type: 'bettermentdb_user_id',
        visitor_id: existing_visitor_id,
        value: "444"
      )
    end

    it "normally doesn't delay identifier creation" do
      expect(existing_visitor.log_in!('bettermentdb_user_id', 444).id).to eq existing_visitor_id

      expect(delayed_identifier_proxy).not_to have_received(:create!)
    end

    context "with stubbed identifier creation" do
      let(:identifier) { TestTrackRails::Identifier.new(visitor: { id: "server_id", assignment_registry: server_registry }) }
      let(:server_registry) { { "foo" => "definitely", "bar" => "occasionally" } }

      before do
        allow(TestTrackRails::Identifier).to receive(:create!).and_return(identifier)
      end

      it "changes id if changed" do
        expect(existing_visitor.log_in!('bettermentdb_user_id', 444).id).to eq 'server_id'
      end

      it "ingests a server-provided assignment as non-new" do
        existing_visitor.log_in!('bettermentdb_user_id', 444)

        expect(existing_visitor.assignment_registry['foo']).to eq 'definitely'
        expect(existing_visitor.new_assignments).not_to have_key 'foo'
      end

      it "preserves a local new assignment with no conflicting server-provided assignment as new" do
        existing_visitor.new_assignments['baz'] = existing_visitor.assignment_registry['baz'] = 'never'

        existing_visitor.log_in!('bettermentdb_user_id', 444)

        expect(existing_visitor.assignment_registry['baz']).to eq 'never'
        expect(existing_visitor.new_assignments['baz']).to eq 'never'
      end

      it "removes and overrides a local new assignment with a conflicting server-provided assignment" do
        existing_visitor.new_assignments['foo'] = existing_visitor.assignment_registry['foo'] = 'something_else'

        existing_visitor.log_in!('bettermentdb_user_id', 444)

        expect(existing_visitor.assignment_registry['foo']).to eq 'definitely'
        expect(existing_visitor.new_assignments).not_to have_key 'foo'
      end

      it "overrides a local existing assignment with a conflicting server-provided assignment" do
        existing_visitor.assignment_registry['foo'] = 'something_else'

        existing_visitor.log_in!('bettermentdb_user_id', 444)

        expect(existing_visitor.assignment_registry['foo']).to eq 'definitely'
        expect(existing_visitor.new_assignments).not_to have_key 'foo'
      end
    end
  end
end
