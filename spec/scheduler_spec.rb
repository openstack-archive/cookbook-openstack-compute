# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-compute::scheduler' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::Runner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'compute_stubs'
    include_examples 'expect_runs_nova_common_recipe'
    include_examples 'expect_creates_nova_lock_dir'

    it 'upgrades nova scheduler package' do
      expect(chef_run).to upgrade_package('nova-scheduler')
    end

    it 'starts nova scheduler' do
      expect(chef_run).to start_service('nova-scheduler')
    end

    it 'starts nova scheduler on boot' do
      expect(chef_run).to enable_service('nova-scheduler')
    end
  end
end
