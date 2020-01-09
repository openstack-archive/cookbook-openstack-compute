# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-compute::placement_api' do
  describe 'redhat' do
    let(:runner) { ChefSpec::SoloRunner.new(REDHAT_OPTS) }
    let(:node) { runner.node }
    cached(:chef_run) { runner.converge(described_recipe) }

    include_context 'compute_stubs'
    include_examples 'expect_runs_nova_common_recipe'
    include_examples 'expect_creates_nova_state_dir'
    include_examples 'expect_creates_nova_lock_dir'

    it 'upgrades placement packages' do
      expect(chef_run).to upgrade_package 'openstack-nova-placement-api'
    end

    it do
      expect(chef_run).to disable_service 'openstack-nova-placement-api'
      expect(chef_run).to stop_service 'openstack-nova-placement-api'
    end

    it do
      expect(chef_run).to_not disable_apache2_site('nova-placement-api')
    end
  end
end
