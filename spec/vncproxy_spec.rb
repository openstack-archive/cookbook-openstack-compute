# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-compute::vncproxy' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    cached(:chef_run) { runner.converge(described_recipe) }

    include_context 'compute_stubs'
    include_examples 'expect_runs_nova_common_recipe'
    include_examples 'expect_creates_nova_state_dir'
    include_examples 'expect_creates_nova_lock_dir'

    it do
      expect(chef_run).to upgrade_package %w(novnc websockify python3-nova nova-novncproxy)
    end

    it 'starts nova vncproxy' do
      expect(chef_run).to start_service('nova-novncproxy')
    end

    it 'starts nova vncproxy on boot' do
      expect(chef_run).to enable_service('nova-novncproxy')
    end
  end
end
