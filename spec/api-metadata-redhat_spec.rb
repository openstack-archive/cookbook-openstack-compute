require_relative 'spec_helper'

describe 'openstack-compute::api-metadata' do
  describe 'redhat' do
    let(:runner) { ChefSpec::SoloRunner.new(REDHAT_OPTS) }
    let(:node) { runner.node }
    cached(:chef_run) { runner.converge(described_recipe) }

    include_context 'compute_stubs'
    include_examples 'expect_runs_nova_apache_recipe'
    include_examples 'expect_creates_nova_state_dir'
    include_examples 'expect_creates_nova_lock_dir'

    it 'upgrades metadata api packages' do
      expect(chef_run).to upgrade_package 'openstack-nova-api'
    end

    it 'disables metadata api on boot' do
      expect(chef_run).to disable_service 'nova-api-metadata'
    end

    it 'stops metadata api now' do
      expect(chef_run).to stop_service 'nova-api-metadata'
    end
  end
end
