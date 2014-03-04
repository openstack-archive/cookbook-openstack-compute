# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-compute::network' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::Runner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'compute_stubs'
    include_examples 'expect_runs_nova_common_recipe'

    context "when service_type is 'nova'" do
      before do
        node.set['openstack']['compute']['network']['service_type'] = 'nova'
      end

      it 'installs nova network packages' do
        expect(chef_run).to upgrade_package('iptables')
        expect(chef_run).to upgrade_package('nova-network')
      end

      it 'starts nova network on boot' do
        expect(chef_run).to enable_service('nova-network')
      end
    end

    context "when service_type is 'neutron'" do
      before do
        node.set['openstack']['compute']['network']['service_type'] = 'neutron'
        node.set['openstack']['compute']['network']['plugins'] = ['openvswitch']
      end

      it 'includes openstack-network recipes for neutron when service type is neutron' do
        expect(chef_run).to include_recipe('openstack-network::openvswitch')
      end
    end
  end
end
