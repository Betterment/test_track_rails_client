require 'rails_helper'

RSpec.describe TestTrack::VisitorDSL do
  let(:visitor) { TestTrack::Visitor.new }
  subject { described_class.new(visitor) }

  it "delegates methods to visitor" do
    expect(subject).to delegate_method(:ab).to(:visitor)
    expect(subject).to delegate_method(:vary).to(:visitor)
    expect(subject).to delegate_method(:log_in!).to(:visitor)
    expect(subject).to delegate_method(:sign_up!).to(:visitor)
  end
end
