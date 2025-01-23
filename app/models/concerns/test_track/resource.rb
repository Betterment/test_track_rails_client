module TestTrack::Resource
  extend ActiveSupport::Concern

  include ActiveModel::API
  include ActiveModel::Attributes

  private

  def _assign_attribute(name, value)
    super
  rescue ActiveModel::UnknownAttributeError
    # Don't raise when we encounter an unknown attribute.
  end
end
