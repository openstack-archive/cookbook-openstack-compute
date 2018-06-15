# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-compute::api-os-compute' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'compute_stubs'
    include_examples 'expect_runs_nova_common_recipe'
    include_examples 'expect_creates_nova_state_dir'
    include_examples 'expect_creates_nova_lock_dir'
    include_examples 'expect_creates_api_paste_template'

    it do
      expect(chef_run).to run_execute('nova-manage api_db sync')
        .with(timeout: 3600,
              user: 'nova',
              group: 'nova',
              command: 'nova-manage api_db sync')
    end

    it 'upgrades openstack api packages' do
      expect(chef_run).to upgrade_package 'nova-api'
    end

    it 'disables openstack api on boot' do
      expect(chef_run).to disable_service 'nova-api-os-compute'
    end

    it 'stops openstack api now' do
      expect(chef_run).to stop_service 'nova-api-os-compute'
    end
  end
end
