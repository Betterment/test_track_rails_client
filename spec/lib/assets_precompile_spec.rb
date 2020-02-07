require 'rails_helper'
require 'rake'

RSpec.describe 'deploy::assets:precompile' do
  before do
    TestTrackRailsClient::Engine.load_tasks
    allow(TesttrackCli.instance).to receive(:project_initialized?).and_return(true)
  end

  it 'calls testtrack generate_build_timestamp' do
    expect(TesttrackCli.instance).to receive(:call).with('generate_build_timestamp')

    with_rails_env('development') do
      Rake::Task['deploy:assets:precompile'].invoke
    end
  end
end
