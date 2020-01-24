BUILD_TIMESTAMP_FILE_PATH = 'testtrack/build_timestamp'.freeze

if Rails.env.test? || Rails.env.dev?
  TestTrack::BuildTimestamp = Time.zone.now
elsif File.exist?(BUILD_TIMESTAMP_FILE_PATH) && File.readable?(BUILD_TIMESTAMP_FILE_PATH) && !File.zero?(BUILD_TIMESTAMP_FILE_PATH)
  TestTrack::BuildTimestamp = File.read(BUILD_TIMESTAMP_FILE_PATH)
else
  raise Exception.new "Failed to read timestamp"
end
