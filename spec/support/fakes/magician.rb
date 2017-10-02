class Magician
  include ActiveModel::Model
  include TestTrack::Identity

  test_track_identifier "magician_id", :id

  attr_accessor :id
end
