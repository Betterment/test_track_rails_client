module TestTrackRails
  class Assignment
    include TestTrackModel

    collection_path '/api/assignment'

    attributes :visitor_id, :split_name, :variant

    validates :visitor_id, :split_name, :variant, presence: true

    def fake_save_response_attributes
      nil # :no_content is the expected response type
    end
  end
end
