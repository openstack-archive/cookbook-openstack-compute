# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-compute::nova-cert' do
  before { compute_stubs }
  describe 'redhat' do
    before do
      @chef_run = ::ChefSpec::Runner.new ::REDHAT_OPTS do |n|
        # TODO: Remove work around once https://github.com/customink/fauxhai/pull/77 merges
        n.set['cpu']['total'] = 1
      end
      @chef_run.converge 'openstack-compute::nova-cert'
    end

    it 'installs nova cert packages' do
      expect(@chef_run).to upgrade_package 'openstack-nova-cert'
    end

    it 'starts nova cert on boot' do
      expect(@chef_run).to enable_service 'openstack-nova-cert'
    end
  end
end
