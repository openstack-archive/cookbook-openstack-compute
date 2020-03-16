# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-compute::serialproxy' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    cached(:chef_run) { runner.converge(described_recipe) }

    include_context 'compute_stubs'
    include_examples 'expect_runs_nova_common_recipe'
    include_examples 'expect_creates_nova_state_dir'
    include_examples 'expect_creates_nova_lock_dir'

    it do
      expect(chef_run).to upgrade_package %w(python3-nova nova-serialproxy)
    end

    it 'starts nova serialproxy' do
      expect(chef_run).to start_service('nova-serialproxy')
    end

    it 'starts nova serialproxy on boot' do
      expect(chef_run).to enable_service('nova-serialproxy')
    end
  end
end
