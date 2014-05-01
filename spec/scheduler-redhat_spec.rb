# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-compute::scheduler' do
  describe 'redhat' do
    let(:runner) { ChefSpec::Runner.new(REDHAT_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'compute_stubs'

    it 'upgrades nova scheduler package' do
      expect(chef_run).to upgrade_package('openstack-nova-scheduler')
    end

    it 'starts nova scheduler' do
      expect(chef_run).to start_service('openstack-nova-scheduler')
    end

    it 'starts nova scheduler on boot' do
      expect(chef_run).to enable_service('openstack-nova-scheduler')
    end
  end
end
