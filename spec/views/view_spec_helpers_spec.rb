require 'rails_helper'
require 'test_track_rails_client/rspec_helpers'

RSpec.describe TestTrackRailsClient::ViewSpecHelpers, type: :view do
  after { ActionView::TestCase::TestController.test_track_identity = :none }

  describe ".install!" do
    it "lets views call test_track_visitor" do
      described_class.install!
      stub_test_track_assignments(blue_button_enabled: true)

      render inline: "<%= test_track_visitor.ab(:blue_button_enabled, context: 'spec') ? 'blue' : 'red' %>"

      expect(rendered).to eq 'blue'
    end

    it "defaults the identity to :none" do
      described_class.install!

      expect(ActionView::TestCase::TestController.test_track_identity).to eq :none
    end

    it "defines a nil identity method when the controller lacks one" do
      described_class.install!(identity: :current_spec_user)

      expect(ActionView::TestCase::TestController.test_track_identity).to eq :current_spec_user
      expect(ActionView::TestCase::TestController.new.current_spec_user).to be_nil
    end

    it "can be called more than once" do
      2.times { described_class.install! }

      expect(ActionView::TestCase::TestController.ancestors.count(TestTrack::Controller)).to eq 1
    end
  end
end
