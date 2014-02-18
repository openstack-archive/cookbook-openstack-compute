# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-compute::libvirt' do
  before { compute_stubs }
  describe 'redhat' do
    before do
      @chef_run = ::ChefSpec::Runner.new ::REDHAT_OPTS
      @chef_run.converge 'openstack-compute::libvirt'
    end

    it 'installs libvirt packages' do
      expect(@chef_run).to install_package 'libvirt'
    end

    it 'creates libvirtd group and adds nova as a member' do
      expect(@chef_run).to create_group 'libvirtd'
      libvirt_group = @chef_run.group('libvirtd')
      libvirt_group.members.should == ['nova']
    end

    it 'symlinks qemu-kvm' do
      link = @chef_run.link '/usr/bin/qemu-system-x86_64'
      expect(link).to link_to '/usr/libexec/qemu-kvm'
    end

    it 'starts libvirt' do
      expect(@chef_run).to start_service 'libvirtd'
    end

    it 'starts libvirt on boot' do
      expect(@chef_run).to enable_service 'libvirtd'
    end

    it 'does not create /etc/default/libvirt-bin' do
      pending 'TODO: how to test this'
    end

    describe '/etc/sysconfig/libvirtd' do
      before { @filename = '/etc/sysconfig/libvirtd' }

      it 'creates the /etc/sysconfig/libvirtd file' do
        expect(@chef_run).to create_template(@filename).with(
          owner: 'root',
          group: 'root',
          mode: 0644
        )
      end

      it 'template contents' do
        pending 'TODO: implement'
      end

      it 'notifies libvirt-bin restart' do
        expect(@chef_run.template(@filename)).to notify('service[libvirt-bin]').to(:restart)
      end
    end
  end
end
