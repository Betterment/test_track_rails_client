require 'digest'

class TestTrack::Fake::Visitor
  attr_reader :id

  Assignment = Struct.new(:split_name, :variant, :unsynced)

  def self.instance
    @instance ||= new(TestTrack::FakeServer.seed)
  end

  def self.reset!
    @instance = nil
  end

  def initialize(id)
    @id = id
  end

  def assignments
    @assignments ||= _assignments
  end

  private

  def _assignments
    TestTrack::Fake::SplitRegistry.instance.splits.map do |split|
      index = hash_fixnum(split.name) % split.registry.keys.size
      variant = split.registry.keys[index]
      Assignment.new(split.name, variant, false)
    end
  end

  def hash_fixnum(split_name)
    split_visitor_hash(split_name).slice(0, 8).to_i(16)
  end

  def split_visitor_hash(split_name)
    Digest::MD5.new.update(split_name.to_s + id.to_s).hexdigest
  end
end
