# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-compute::libvirt' do
  describe 'redhat' do
    let(:runner) { ChefSpec::Runner.new(REDHAT_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'compute_stubs'

    it 'upgrades libvirt packages' do
      expect(chef_run).to upgrade_package 'libvirt'
      expect(chef_run).to upgrade_package 'device-mapper'
    end

    it 'creates libvirtd group and adds nova as a member' do
      expect(chef_run).to create_group('libvirtd').with(members: ['nova'])
    end

    it 'symlinks qemu-kvm' do
      expect(chef_run).to create_link('/usr/bin/qemu-system-x86_64').with(to: '/usr/libexec/qemu-kvm')
    end

    it 'starts libvirt' do
      expect(chef_run).to start_service 'libvirtd'
    end

    it 'starts libvirt on boot' do
      expect(chef_run).to enable_service 'libvirtd'
    end

    it 'does not create /etc/default/libvirt-bin' do
      expect(chef_run).not_to create_template('/etc/default/libvirt-bin')
    end

    describe '/etc/sysconfig/libvirtd' do
      let(:file) { chef_run.template('/etc/sysconfig/libvirtd') }

      it 'creates the /etc/sysconfig/libvirtd file' do
        expect(chef_run).to create_template(file.name).with(
          owner: 'root',
          group: 'root',
          mode: 0644
        )
      end

      it 'template contents' do
        expect(chef_run).to render_file(file.name)
          .with_content(/^LIBVIRTD_ARGS="--listen"$/)
      end

      it 'notifies libvirt-bin restart' do
        expect(file).to notify('service[libvirt-bin]').to(:restart)
      end
    end
  end
end
