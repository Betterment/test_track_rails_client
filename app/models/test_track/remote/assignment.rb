class TestTrack::Remote::Assignment
  include TestTrack::Resource
  include ActiveModel::Dirty

  attribute :split_name
  attribute :variant
  attribute :context
  attribute :unsynced, :boolean

  validates :split_name, :variant, :mixpanel_result, presence: true

  def unsynced?
    unsynced || variant_changed?
  end

  def feature_gate?
    split_name.end_with?('_enabled')
  end

  def self.fake_instance_attributes(id)
    {
      split_name: "split_#{id}",
      variant: "true",
      context: "context",
      unsynced: false
    }
  end
end
