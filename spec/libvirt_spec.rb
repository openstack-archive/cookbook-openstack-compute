# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-compute::libvirt' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::Runner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'compute_stubs'

    it 'upgrades libvirt packages' do
      expect(chef_run).to upgrade_package 'libvirt-bin'
    end

    it 'does not create libvirtd group and add to nova' do
      pending 'TODO: how to test this'
    end

    it 'does not symlink qemu-kvm' do
      pending 'TODO: how to test this'
    end

    it 'starts dbus' do
      expect(chef_run).to start_service 'dbus'
    end

    it 'starts dbus on boot' do
      expect(chef_run).to enable_service 'dbus'
    end

    it 'starts libvirt' do
      expect(chef_run).to start_service 'libvirt-bin'
    end

    it 'starts libvirt on boot' do
      expect(chef_run).to enable_service 'libvirt-bin'
    end

    it 'disables default libvirt network' do
      expect(chef_run).to run_execute('virsh net-autostart default --disable')
    end

    it 'deletes default libvirt network' do
      expect(chef_run).to run_execute('virsh net-destroy default')
    end

    describe 'rbd/ceph volume storage' do
      before do
        node.set['openstack']['compute']['libvirt']['volume_backend'] = 'rbd'
      end

      it 'includes the libvirt_rbd recipe if it is the selected volume backend' do
        expect(chef_run).to include_recipe('openstack-compute::libvirt_rbd')
      end
    end

    describe '/etc/libvirt/libvirtd.conf' do
      let(:file) { chef_run.template('/etc/libvirt/libvirtd.conf') }

      it 'creates the /etc/libvirt/libvirtd.conf file' do
        expect(chef_run).to create_template(file.name).with(
          owner: 'root',
          group: 'root',
          mode: 0644
        )
      end

      it 'has proper processing controls' do
        [/^max_clients = 20$/, /^max_workers = 20$/, /^max_requests = 20$/, /^max_client_requests = 5$/].each do |content|
          expect(chef_run).to render_file(file.name).with_content(content)
        end
      end

      it 'has unix_sock_rw_perms' do
        expect(chef_run).to render_file(file.name).with_content(/^unix_sock_rw_perms = "0770"$/)
      end

      it 'notifies libvirt-bin restart' do
        expect(file).to notify('service[libvirt-bin]').to(:restart)
      end
    end

    describe '/etc/default/libvirt-bin' do
      let(:file) { chef_run.template('/etc/default/libvirt-bin') }

      it 'creates the /etc/default/libvirt-bin file' do
        expect(chef_run).to create_template(file.name).with(
          owner: 'root',
          group: 'root',
          mode: 0644
        )
      end

      it 'template contents' do
        [
          /^start_libvirtd="yes"$/,
          /^libvirtd_opts="-d -l"$/
        ].each do |line|
          expect(chef_run).to render_file(file.name).with_content(line)
        end
      end

      it 'notifies libvirt-bin restart' do
        expect(file).to notify('service[libvirt-bin]').to(:restart)
      end
    end

    it 'does not create /etc/sysconfig/libvirtd' do
      pending 'TODO: how to test this'
    end
  end
end
