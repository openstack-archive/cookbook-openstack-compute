# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-compute::nova-cert' do
  before { compute_stubs }
  describe 'ubuntu' do
    before do
      @chef_run = ::ChefSpec::Runner.new ::UBUNTU_OPTS do |n|
        # TODO: Remove work around once https://github.com/customink/fauxhai/pull/77 merges
        n.set['cpu']['total'] = 1
      end
      @chef_run.converge 'openstack-compute::nova-cert'
    end

    expect_runs_nova_common_recipe

    it 'installs nova cert packages' do
      expect(@chef_run).to upgrade_package 'nova-cert'
    end

    it 'starts nova cert on boot' do
      expect(@chef_run).to enable_service 'nova-cert'
    end
  end
end
