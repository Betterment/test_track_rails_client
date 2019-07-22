require 'rails_helper'

RSpec.describe TesttrackCli do
  describe '#skip_testtrack_cli?' do
    subject { TesttrackCli.instance.skip_testtrack_cli? }

    before do |example|
      mock_env = example.metadata[:env] || 'production'
      allow(Rails).to receive(:env) { mock_env.inquiry }
      allow(ENV).to receive(:key?).with('SKIP_TESTTRACK_CLI') { true } if example.metadata[:env_skip]
      allow(TesttrackCli.instance).to receive(:project_initialized?) { example.metadata[:project_initialized].present? }
    end

    it { is_expected.to eq(false) }

    context 'SKIP_TESTTRACK_CLI=1', env_skip: true do
      it { is_expected.to eq(true) }
    end

    context 'Rails.env.test?', env: 'test' do
      it { is_expected.to eq(true) }
    end

    context 'project_initialized?', project_initialized: true do
      it { is_expected.to eq(false) }

      context 'SKIP_TESTTRACK_CLI=1', env_skip: true do
        it { is_expected.to eq(true) }
      end
    end

    context 'Rails.env.development?', env: 'development' do
      it { is_expected.to eq(false) }

      context 'project_initialized?', project_initialized: true do
        it { is_expected.to eq(true) }
      end

      context 'SKIP_TESTTRACK_CLI=1', env_skip: true do
        it { is_expected.to eq(true) }
      end
    end
  end
end
