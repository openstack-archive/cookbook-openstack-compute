# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-compute::api-ec2' do
  before { compute_stubs }
  describe 'ubuntu' do
    before do
      @chef_run = ::ChefSpec::Runner.new ::UBUNTU_OPTS do |n|
        # TODO: Remove work around once https://github.com/customink/fauxhai/pull/77 merges
        n.set['cpu']['total'] = 1
      end
      @chef_run.converge 'openstack-compute::api-ec2'
    end

    expect_runs_nova_common_recipe

    expect_creates_nova_lock_dir

    expect_installs_python_keystone

    it 'installs ec2 api packages' do
      expect(@chef_run).to upgrade_package 'nova-api-ec2'
    end

    it 'starts ec2 api on boot' do
      expect(@chef_run).to enable_service 'nova-api-ec2'
    end

    expect_creates_api_paste 'service[nova-api-ec2]'
  end
end
