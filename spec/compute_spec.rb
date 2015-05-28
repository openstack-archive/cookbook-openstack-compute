# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-compute::compute' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'compute_stubs'
    include_examples 'expect_runs_nova_common_recipe'
    include_examples 'expect_creates_nova_state_dir'
    include_examples 'expect_creates_nova_lock_dir'
    include_examples 'expect_creates_nova_instances_dir'

    it 'upgrades volume utils packages' do
      %w(sysfsutils sg3-utils multipath-tools).each do |pkg|
        expect(chef_run).to upgrade_package(pkg)
      end
    end

    it 'includes api-metadata recipe' do
      expect(chef_run).to include_recipe 'openstack-compute::api-metadata'
    end

    it 'does not include api-metadata recipe' do
      chef_run = ::ChefSpec::SoloRunner.new ::UBUNTU_OPTS
      node = chef_run.node
      node.set['openstack']['compute']['enabled_apis'] = 'ec2,osapi_compute'
      chef_run.converge 'openstack-compute::compute'

      expect(chef_run).not_to include_recipe 'openstack-compute::api-metadata'
    end

    it 'runs network recipe' do
      expect(chef_run).to include_recipe 'openstack-compute::network'
    end

    it 'upgrades nova compute package' do
      expect(chef_run).to upgrade_package 'nova-compute'
    end

    it 'upgrades nfs client package' do
      expect(chef_run).to upgrade_package 'nfs-common'
    end

    it "upgrades kvm when virt_type is 'kvm'" do
      node.set['openstack']['compute']['libvirt']['virt_type'] = 'kvm'

      expect(chef_run).to upgrade_package 'nova-compute-kvm'
      expect(chef_run).not_to upgrade_package 'nova-compute-qemu'
    end

    it 'honors the package options platform overrides for kvm' do
      node.set['openstack']['compute']['libvirt']['virt_type'] = 'kvm'
      node.set['openstack']['compute']['platform']['package_overrides'] = '-o Dpkg::Options::=\'--force-confold\' -o Dpkg::Options::=\'--force-confdef\' --force-yes'

      expect(chef_run).to upgrade_package('nova-compute-kvm').with(options: '-o Dpkg::Options::=\'--force-confold\' -o Dpkg::Options::=\'--force-confdef\' --force-yes')
    end

    it 'upgrades qemu when virt_type is qemu' do
      node.set['openstack']['compute']['libvirt']['virt_type'] = 'qemu'

      expect(chef_run).to upgrade_package 'nova-compute-qemu'
      expect(chef_run).not_to upgrade_package 'nova-compute-kvm'
    end

    it 'honors the package options platform overrides for qemu' do
      node.set['openstack']['compute']['libvirt']['virt_type'] = 'qemu'
      node.set['openstack']['compute']['platform']['package_overrides'] = '-o Dpkg::Options::=\'--force-confold\' -o Dpkg::Options::=\'--force-confdef\' --force-yes'

      expect(chef_run).to upgrade_package('nova-compute-qemu').with(options: '-o Dpkg::Options::=\'--force-confold\' -o Dpkg::Options::=\'--force-confdef\' --force-yes')
    end

    %w(qemu kvm).each do |virt_type|
      it "honors the package name platform overrides for #{virt_type}" do
        node.set['openstack']['compute']['libvirt']['virt_type'] = virt_type
        node.set['openstack']['compute']['platform']["#{virt_type}_compute_packages"] = ["my-nova-#{virt_type}"]

        expect(chef_run).to upgrade_package("my-nova-#{virt_type}")
      end
    end

    describe 'nova-compute.conf' do
      let(:file) { chef_run.cookbook_file('/etc/nova/nova-compute.conf') }

      it 'creates the file' do
        expect(chef_run).to create_cookbook_file(file.name).with(
          source: 'nova-compute.conf',
          mode: 00644
        )
      end
    end

    it 'runs libvirt recipe' do
      expect(chef_run).to include_recipe 'openstack-compute::libvirt'
    end

    it 'starts nova compute on boot' do
      expect(chef_run).to enable_service 'nova-compute'
    end

    it 'starts nova compute' do
      expect(chef_run).to start_service 'nova-compute'
    end

    it 'does not include docker-setup recipe' do
      expect(chef_run).not_to include_recipe 'openstack-compute::docker-setup'
    end

    it 'does not create docker group' do
      expect(chef_run).not_to create_group('docker')
    end

    it 'does not manage docker group' do
      expect(chef_run).not_to manage_group('docker')
    end

    it 'does not create docker filter file' do
      expect(chef_run).not_to create_file('/etc/nova/rootwrap.d/docker.filters')
    end

    context 'when docker is enabled' do
      before do
        node.set['openstack']['compute']['docker']['enable'] = true
      end

      it 'includes docker-setup recipe' do
        expect(chef_run).to include_recipe 'openstack-compute::docker-setup'
      end

      it 'creates docker group' do
        expect(chef_run).to create_group('docker')
      end

      it 'manages docker group' do
        expect(chef_run).to manage_group('docker')
      end

      it 'creates a file with attributes' do
        expect(chef_run).to create_file('/etc/nova/rootwrap.d/docker.filters').with(
          user:   'root',
          group:  'root',
          mode:   0644,
          path:   '/etc/nova/rootwrap.d/docker.filters'
        )
      end

      it 'configures compute service to subscribe for docker filter' do
        expect(chef_run.service('nova-compute')).to subscribe_to('file[docker.filter]')
      end
    end
  end
end
