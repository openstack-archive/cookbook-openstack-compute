# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-compute::vncproxy' do
  before { compute_stubs }
  describe 'redhat' do
    before do
      @chef_run = ::ChefSpec::Runner.new ::REDHAT_OPTS do |n|
        # TODO: Remove work around once https://github.com/customink/fauxhai/pull/77 merges
        n.set['cpu']['total'] = 1
      end
      @chef_run.converge 'openstack-compute::vncproxy'
    end

    expect_runs_nova_common_recipe

    it 'installs nova vncproxy packages' do
      expect(@chef_run).to upgrade_package 'openstack-nova-novncproxy'
    end

    it 'installs nova consoleauth packages' do
      expect(@chef_run).to upgrade_package 'openstack-nova-console'
    end

    it 'starts nova vncproxy' do
      expect(@chef_run).to start_service 'openstack-nova-novncproxy'
    end

    it 'starts nova vncproxy on boot' do
      expected = 'openstack-nova-novncproxy'
      expect(@chef_run).to enable_service expected
    end

    it 'starts nova consoleauth' do
      expect(@chef_run).to start_service 'openstack-nova-consoleauth'
    end

    it 'starts nova consoleauth on boot' do
      expected = 'openstack-nova-consoleauth'
      expect(@chef_run).to enable_service expected
    end
  end
end
