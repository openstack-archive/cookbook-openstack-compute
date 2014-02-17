# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-compute::scheduler' do
  before { compute_stubs }
  describe 'redhat' do
    before do
      @chef_run = ::ChefSpec::Runner.new ::REDHAT_OPTS do |n|
        # TODO: Remove work around once https://github.com/customink/fauxhai/pull/77 merges
        n.set['cpu']['total'] = 1
      end
      @chef_run.converge 'openstack-compute::scheduler'
    end

    it 'installs nova scheduler packages' do
      expect(@chef_run).to upgrade_package 'openstack-nova-scheduler'
    end

    it 'starts nova scheduler' do
      expect(@chef_run).to start_service 'openstack-nova-scheduler'
    end

    it 'starts nova scheduler on boot' do
      expected = 'openstack-nova-scheduler'
      expect(@chef_run).to enable_service expected
    end
  end
end
