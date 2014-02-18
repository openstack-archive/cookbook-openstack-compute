# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-compute::api-os-compute' do
  before { compute_stubs }
  describe 'redhat' do
    before do
      @chef_run = ::ChefSpec::Runner.new ::REDHAT_OPTS
      @chef_run.converge 'openstack-compute::api-os-compute'
    end

    it 'installs openstack api packages' do
      expect(@chef_run).to upgrade_package 'openstack-nova-api'
    end

    it 'starts openstack api on boot' do
      expect(@chef_run).to enable_service 'openstack-nova-api'
    end
  end
end
