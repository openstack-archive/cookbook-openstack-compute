# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-compute::network' do
  describe 'redhat' do
    let(:runner) { ChefSpec::Runner.new(REDHAT_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'compute_stubs'

    it 'installs nova network packages' do
      expect(chef_run).to upgrade_package('iptables')
      expect(chef_run).to upgrade_package('openstack-nova-network')
    end

    it 'starts nova network on boot' do
      expect(chef_run).to enable_service('openstack-nova-network')
    end
  end
end
