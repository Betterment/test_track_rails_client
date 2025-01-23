class TestTrack::Remote::AssignmentEvent
  include TestTrack::Resource

  attribute :visitor_id
  attribute :split_name
  attribute :mixpanel_result
  attribute :context
  attribute :unsynced, :boolean

  validates :visitor_id, :split_name, :mixpanel_result, presence: true

  alias unsynced? unsynced

  def self.create!(attributes)
    assignment_event = new(attributes)
    assignment_event.validate!
    assignment_event.save
    assignment_event
  end

  def save
    return false unless valid?

    TestTrack::Client.request(
      method: :post,
      path: 'api/v1/assignment_event',
      body: { context: context, visitor_id: visitor_id, split_name: split_name, mixpanel_result: mixpanel_result },
      fake: nil
    )

    true
  end
end
