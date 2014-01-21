# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-compute::network' do
  before { compute_stubs }
  describe 'redhat' do
    before do
      @chef_run = ::ChefSpec::Runner.new ::REDHAT_OPTS
      @chef_run.converge 'openstack-compute::network'
    end

    it 'installs nova network packages' do
      expect(@chef_run).to upgrade_package 'iptables'
      expect(@chef_run).to upgrade_package 'openstack-nova-network'
    end

    it 'starts nova network on boot' do
      expected = 'openstack-nova-network'
      expect(@chef_run).to enable_service expected
    end
  end
end
