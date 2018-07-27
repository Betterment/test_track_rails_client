class TestTrack::ApplicationIdentity
	include Singleton
	include TestTrack::Identity

	test_track_identifier :app_id, :app_name

	private

	def app_name
		raise 'must configure TestTrack.app_name on application initialization' unless TestTrack.app_name.present?
		TestTrack.app_name
	end
end