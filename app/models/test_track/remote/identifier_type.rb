class TestTrack::Remote::IdentifierType
  include TestTrack::Resource
  include TestTrack::Persistence

  attribute :name

  validates :name, presence: true

  private

  def persist!
    TestTrack::Client.request(
      method: :post,
      path: 'api/v1/identifier_type',
      body: { name: name },
      fake: nil
    )
  end
end
