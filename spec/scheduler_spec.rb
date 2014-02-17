# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-compute::scheduler' do
  before { compute_stubs }
  describe 'ubuntu' do
    before do
      @chef_run = ::ChefSpec::Runner.new ::UBUNTU_OPTS do |n|
        # TODO: Remove work around once https://github.com/customink/fauxhai/pull/77 merges
        n.set['cpu']['total'] = 1
      end
      @chef_run.converge 'openstack-compute::scheduler'
    end

    expect_runs_nova_common_recipe

    expect_creates_nova_lock_dir

    it 'installs nova scheduler packages' do
      expect(@chef_run).to upgrade_package 'nova-scheduler'
    end

    it 'starts nova scheduler' do
      expect(@chef_run).to start_service 'nova-scheduler'
    end

    it 'starts nova scheduler on boot' do
      expect(@chef_run).to enable_service 'nova-scheduler'
    end
  end
end
