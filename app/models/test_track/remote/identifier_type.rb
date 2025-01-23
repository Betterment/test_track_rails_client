class TestTrack::Remote::IdentifierType
  include TestTrack::Resource

  attribute :name

  validates :name, presence: true

  def save
    return false unless valid?

    request(
      method: :post,
      path: 'api/v1/identifier_type',
      body: { name: name },
      fake: nil
    )

    true
  end
end
