# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-compute::compute' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    cached(:chef_run) { runner.converge(described_recipe) }

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

    it 'does not include the api-metadata recipe' do
      expect(chef_run).not_to include_recipe 'openstack-compute::api-metadata'
    end

    it 'does not include api-metadata recipe' do
      expect(chef_run).not_to include_recipe 'openstack-compute::api-metadata'
    end

    it 'upgrades nova compute package' do
      expect(chef_run).to upgrade_package 'nova-compute'
    end

    context "upgrades kvm when virt_type is 'kvm'" do
      cached(:chef_run) do
        node.override['openstack']['compute']['conf']['libvirt']['virt_type'] = 'kvm'
        runner.converge(described_recipe)
      end
      it do
        expect(chef_run).to upgrade_package 'nova-compute-kvm'
        expect(chef_run).not_to upgrade_package 'nova-compute-qemu'
      end
    end

    context 'upgrades qemu when virt_type is qemu' do
      cached(:chef_run) do
        node.override['openstack']['compute']['conf']['libvirt']['virt_type'] = 'qemu'
        runner.converge(described_recipe)
      end
      it do
        expect(chef_run).to upgrade_package 'nova-compute-qemu'
        expect(chef_run).not_to upgrade_package 'nova-compute-kvm'
      end
    end

    %w(qemu kvm).each do |virt_type|
      context "honors the package name platform overrides for #{virt_type}" do
        cached(:chef_run) do
          node.override['openstack']['compute']['conf']['libvirt']['virt_type'] = virt_type
          node.override['openstack']['compute']['platform']["#{virt_type}_compute_packages"] = ["my-nova-#{virt_type}"]
          runner.converge(described_recipe)
        end
        it do
          expect(chef_run).to upgrade_package("my-nova-#{virt_type}")
        end
      end
    end

    describe 'nova-compute.conf' do
      let(:file) { chef_run.cookbook_file('/etc/nova/nova-compute.conf') }

      it 'creates the file' do
        expect(chef_run).to create_cookbook_file(file.name).with(
          source: 'nova-compute.conf',
          mode: 0o0644
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
  end
end
