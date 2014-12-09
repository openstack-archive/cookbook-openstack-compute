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

      it 'upgrades nova network packages' do
        expect(chef_run).to upgrade_package('iptables')
        expect(chef_run).to upgrade_package('nova-network')
      end

      it 'starts nova network on boot' do
        expect(chef_run).to enable_service('nova-network')
      end
    end

    context "when service_type is 'neutron'" do
      let(:file) { chef_run.template('/etc/nova/nova.conf') }

      before do
        node.set['openstack']['compute']['network']['service_type'] = 'neutron'
        node.set['openstack']['compute']['network']['plugins'] = ['openvswitch']
      end

      it 'includes openstack-network recipes for neutron when service type is neutron' do
        expect(chef_run).to include_recipe('openstack-network::openvswitch')
      end

      it 'includes neutron section defaults' do
        [
          %r{^url=http://127.0.0.1:9696$},
          /^auth_strategy=keystone$/,
          /^admin_tenant_name=service$/,
          /^admin_username=neutron$/,
          /^admin_password=neutron-pass$/,
          %r{^admin_auth_url=http://127.0.0.1:5000/v2.0$},
          /^url_timeout=30$/,
          /^region_name=$/,
          /^ovs_bridge=br-int$/,
          /^extension_sync_interval=600$/,
          /^ca_certificates_file=$/,
          /^service_metadata_proxy=true$/,
          /^metadata_proxy_shared_secret=metadata-secret$/
        ].each do |line|
          expect(chef_run).to render_config_file(file.name)\
            .with_section_content('neutron', line)
        end

        [
          /^network_api_class=nova.network.neutronv2.api.API$/,
          /^linuxnet_interface_driver=nova.network.linux_net.LinuxOVSInterfaceDriver$/,
          /^security_group_api=neutron$/,
          /^default_floating_pool=public$/,
          /^dns_server=8.8.8.8$/
        ].each do |line|
          expect(chef_run).to render_file(file.name).with_content(line)
        end
      end
    end
  end
end
