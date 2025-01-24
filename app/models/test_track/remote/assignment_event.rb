class TestTrack::Remote::AssignmentEvent
  include TestTrack::Resource
  include TestTrack::Persistence

  attribute :visitor_id
  attribute :split_name
  attribute :mixpanel_result
  attribute :context
  attribute :unsynced, :boolean

  validates :visitor_id, :split_name, :mixpanel_result, presence: true

  alias unsynced? unsynced

  private

  def persist!
    TestTrack::Client.request(
      method: :post,
      path: 'api/v1/assignment_event',
      body: { context:, visitor_id:, split_name:, mixpanel_result: },
      fake: nil
    )
  end
end
