class TestTrack::Remote::Assignment
  include TestTrack::RemoteModel

  attributes :split_name, :variant, :context, :unsynced

  validates :split_name, :variant, :mixpanel_result, presence: true

  def unsynced?
    unsynced || variant_changed?
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
