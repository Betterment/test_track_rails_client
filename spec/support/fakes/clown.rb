class Clown
  include ActiveModel::Model
  include TestTrack::Identity

  test_track_identifier "clown_id", :id

  attr_accessor :id
end
