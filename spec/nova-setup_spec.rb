# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-compute::nova-setup' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::Runner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'compute_stubs'
    include_examples 'expect_runs_nova_common_recipe'

    it 'runs db migrations' do
      expect(chef_run).to run_execute('nova-manage db sync').with(user: 'nova', group: 'nova')
    end

    it 'adds nova network ipv4 addresses' do
      cmd = ['nova-manage network create --label=public',
             '--fixed_range_v4=192.168.100.0/24',
             "--multi_host='T'",
             '--num_networks=1',
             '--network_size=255',
             '--bridge=br100',
             '--dns1=8.8.8.8',
             '--dns2=8.8.4.4',
             '--bridge_interface=eth2'].join(' ')
      expect(chef_run).to run_execute(cmd).with(user: 'nova', group: 'nova')
    end

    it 'add_floaters.py has proper modes' do
      file = chef_run.cookbook_file('/usr/local/bin/add_floaters.py')
      expect(sprintf('%o', file.mode)).to eq '755'
    end

    it 'adds cidr range of floating ipv4 addresses' do
      node.set['openstack']['compute']['network']['floating']['ipv4_cidr'] = '10.10.10.0/24'

      expect(chef_run).to run_execute(
        '/usr/local/bin/add_floaters.py nova --cidr=10.10.10.0/24')
    end

    it 'adds range of floating ipv4 addresses' do
      node.set['openstack']['compute']['network'] = {
        'floating' => {
          'ipv4_range' => '10.10.10.1,10.10.10.5'
        }
      }

      expect(chef_run).to run_execute('/usr/local/bin/add_floaters.py nova --ip-range=10.10.10.1,10.10.10.5')
    end

    context 'when neutron is used' do
      before do
        node.set['openstack']['compute']['network']['service_type'] = 'neutron'
        node.set['openstack']['compute']['network']['floating']['ipv4_cidr'] = '10.10.10.0/24'
        node.set['openstack']['compute']['network']['floating']['public_network_name'] = 'public'
      end

      it 'upgrades the neutron python packages' do
        expect(chef_run).to upgrade_package('python-neutronclient')
        expect(chef_run).to upgrade_package('python-pyparsing')
      end

      it 'include common openrc recipe' do
        expect(chef_run).to include_recipe('openstack-common::openrc')
      end

      it 'adds cidr range of floating ipv4 addresses to neutron' do
        resource = chef_run.find_resource('execute', 'neutron floating create').to_hash
        expect(resource).to include(action: [:run], command: '. /root/openrc && /usr/local/bin/add_floaters.py neutron --cidr=10.10.10.0/24 --pool=public')
      end
    end
  end
end
