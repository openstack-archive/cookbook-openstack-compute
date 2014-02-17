# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-compute::conductor' do
  before { compute_stubs }
  describe 'ubuntu' do
    before do
      @chef_run = ::ChefSpec::Runner.new ::UBUNTU_OPTS do |n|
        # TODO: Remove work around once https://github.com/customink/fauxhai/pull/77 merges
        n.set['cpu']['total'] = 1
      end
      @chef_run.converge 'openstack-compute::conductor'
    end

    expect_runs_nova_common_recipe

    it 'installs conductor packages' do
      expect(@chef_run).to upgrade_package 'nova-conductor'
    end

    it 'starts nova-conductor on boot' do
      expect(@chef_run).to enable_service 'nova-conductor'
    end

    it 'starts nova-conductor' do
      expect(@chef_run).to start_service 'nova-conductor'
    end
  end
end
