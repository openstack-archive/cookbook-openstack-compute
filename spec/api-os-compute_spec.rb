# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-compute::api-os-compute' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::Runner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'compute_stubs'
    include_examples 'expect_runs_nova_common_recipe'
    include_examples 'expect_creates_nova_state_dir'
    include_examples 'expect_creates_nova_lock_dir'
    include_examples 'expect_upgrades_python_keystoneclient'

    it 'creates the /var/cache/nova directory' do
      expect(chef_run).to create_directory('/var/cache/nova').with(
        user: 'nova',
        group: 'nova',
        mode: 0700
      )
    end

    it 'upgrades openstack api packages' do
      expect(chef_run).to upgrade_package 'nova-api-os-compute'
    end

    it 'starts openstack api on boot' do
      expect(chef_run).to enable_service 'nova-api-os-compute'
    end

    it 'starts openstack api now' do
      expect(chef_run).to start_service 'nova-api-os-compute'
    end

    expect_creates_api_paste 'service[nova-api-os-compute]'
  end
end
