# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-compute::libvirt' do
  before { compute_stubs }
  describe 'ubuntu' do
    before do
      @chef_run = ::ChefSpec::Runner.new ::UBUNTU_OPTS do |n|
        # TODO: Remove work around once https://github.com/customink/fauxhai/pull/77 merges
        n.set['cpu']['total'] = 1
      end
      @chef_run.converge 'openstack-compute::libvirt'
    end

    it 'installs libvirt packages' do
      expect(@chef_run).to install_package 'libvirt-bin'
    end

    it 'does not create libvirtd group and add to nova' do
      pending 'TODO: how to test this'
    end

    it 'does not symlink qemu-kvm' do
      pending 'TODO: how to test this'
    end

    it 'starts dbus' do
      expect(@chef_run).to start_service 'dbus'
    end

    it 'starts dbus on boot' do
      expect(@chef_run).to enable_service 'dbus'
    end

    it 'starts libvirt' do
      expect(@chef_run).to start_service 'libvirt-bin'
    end

    it 'starts libvirt on boot' do
      expect(@chef_run).to enable_service 'libvirt-bin'
    end

    it 'disables default libvirt network' do
      expect(@chef_run).to run_execute('virsh net-autostart default --disable')
    end

    it 'deletes default libvirt network' do
      expect(@chef_run).to run_execute('virsh net-destroy default')
    end

    describe '/etc/libvirt/libvirtd.conf' do
      before { @filename = '/etc/libvirt/libvirtd.conf' }

      it 'creates the /etc/libvirt/libvirtd.conf file' do
        expect(@chef_run).to create_template(@filename).with(
          owner: 'root',
          group: 'root',
          mode: 0644
        )
      end

      it 'has proper processing controls' do
        [/^max_clients = 20$/, /^max_workers = 20$/, /^max_requests = 20$/, /^max_client_requests = 5$/].each do |content|
          expect(@chef_run).to render_file(@filename).with_content(content)
        end
      end

      it 'notifies libvirt-bin restart' do
        expect(@chef_run.template(@filename)).to notify('service[libvirt-bin]').to(:restart)
      end
    end

    describe '/etc/default/libvirt-bin' do
      before { @filename = '/etc/default/libvirt-bin' }

      it 'creates the /etc/default/libvirt-bin file' do
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

    it 'does not create /etc/sysconfig/libvirtd' do
      pending 'TODO: how to test this'
    end
  end
end
