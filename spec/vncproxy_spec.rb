# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-compute::vncproxy' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'compute_stubs'
    include_examples 'expect_runs_nova_common_recipe'
    include_examples 'expect_creates_nova_state_dir'
    include_examples 'expect_creates_nova_lock_dir'

    it 'upgrades nova vncproxy packages' do
      expect(chef_run).to upgrade_package('novnc')
      expect(chef_run).to upgrade_package('websockify')
      expect(chef_run).to upgrade_package('nova-novncproxy')
    end

    it 'upgrades nova consoleauth package' do
      expect(chef_run).to upgrade_package('nova-consoleauth')
    end

    it 'starts nova vncproxy' do
      expect(chef_run).to start_service('nova-novncproxy')
    end

    it 'starts nova vncproxy on boot' do
      expect(chef_run).to enable_service('nova-novncproxy')
    end

    it 'starts nova consoleauth' do
      expect(chef_run).to start_service('nova-consoleauth')
    end

    it 'starts nova consoleauth on boot' do
      expect(chef_run).to enable_service('nova-consoleauth')
    end
  end
end
