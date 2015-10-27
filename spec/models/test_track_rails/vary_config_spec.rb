require 'rails_helper'

RSpec.describe TestTrackRails::VaryConfig do
  let(:vary_config) { described_class.new(:blue_button, :true, split_registry) }
  let(:split_registry) do
    {
      'blue_button' => {
        'false' => 50,
        'true' => 50
      },
      'quagmire' => {
        'untenable' => 50,
        'manageable' => 50
      },
      'time' => {
        'hammertime' => 100,
        'shoveltime' => 0
      }
    }
  end

  it "isn't defaulted by default" do
    expect(vary_config.defaulted?).to be_falsey
  end

  context "#default" do
    it "accepts a block" do
      vary_config.when :hello do
        puts "hello"
      end
      expect(vary_config.branches['hello']).to be_a Proc
    end

    xit "accepts a proc" do
      vary_config.when :hello, -> { puts "hello" }

      expect(vary_config.branches['hello']).to be_a Proc
    end
  end
end
