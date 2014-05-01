# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-compute::vncproxy' do
  describe 'redhat' do
    let(:runner) { ChefSpec::Runner.new(REDHAT_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'compute_stubs'

    it 'upgrades nova vncproxy package' do
      expect(chef_run).to upgrade_package('openstack-nova-novncproxy')
    end

    it 'upgrades nova consoleauth package' do
      expect(chef_run).to upgrade_package('openstack-nova-console')
    end

    it 'starts nova vncproxy' do
      expect(chef_run).to start_service('openstack-nova-novncproxy')
    end

    it 'starts nova vncproxy on boot' do
      expect(chef_run).to enable_service('openstack-nova-novncproxy')
    end

    it 'starts nova consoleauth' do
      expect(chef_run).to start_service('openstack-nova-consoleauth')
    end

    it 'starts nova consoleauth on boot' do
      expect(chef_run).to enable_service('openstack-nova-consoleauth')
    end
  end
end
