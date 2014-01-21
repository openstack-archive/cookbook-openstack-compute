# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-compute::api-os-compute' do
  before { compute_stubs }
  describe 'ubuntu' do
    before do
      @chef_run = ::ChefSpec::Runner.new ::UBUNTU_OPTS
      @chef_run.converge 'openstack-compute::api-os-compute'
    end

    expect_runs_nova_common_recipe

    expect_creates_nova_lock_dir

    it 'creates the /var/cache/nova directory' do
      expect(@chef_run).to create_directory('/var/cache/nova').with(
        user: 'nova',
        group: 'nova',
        mode: 0700
      )
    end

    expect_installs_python_keystone

    it 'installs openstack api packages' do
      expect(@chef_run).to upgrade_package 'nova-api-os-compute'
    end

    it 'starts openstack api on boot' do
      expect(@chef_run).to enable_service 'nova-api-os-compute'
    end

    it 'starts openstack api now' do
      expect(@chef_run).to start_service 'nova-api-os-compute'
    end

    expect_creates_api_paste 'service[nova-api-os-compute]'
  end
end
