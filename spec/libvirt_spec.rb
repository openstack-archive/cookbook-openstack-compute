require_relative 'spec_helper'

describe 'openstack-compute::libvirt' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    cached(:chef_run) { runner.converge(described_recipe) }

    include_context 'compute_stubs'

    it do
      expect(chef_run).to upgrade_package %w(libvirt-bin python3-guestfs)
    end

    it 'does not create libvirt group and add to nova' do
      expect(chef_run).not_to create_group 'libvirt'
    end

    it 'does not symlink qemu-kvm' do
      expect(chef_run).not_to create_link '/usr/bin/qemu-system-x86_64'
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

    it 'deletes default libvirt network' do
      expect(chef_run).to run_execute('virsh net-destroy default')
    end

    describe '/etc/libvirt/libvirtd.conf' do
      let(:file) { chef_run.template('/etc/libvirt/libvirtd.conf') }

      it 'creates the /etc/libvirt/libvirtd.conf file' do
        expect(chef_run).to create_template(file.name).with(
          source: 'libvirtd.conf.erb',
          owner: 'root',
          group: 'root',
          mode: '644'
        )
      end

      it 'has proper processing controls' do
        [
          /^max_clients = 20$/,
          /^max_workers = 20$/,
          /^max_requests = 20$/,
          /^max_client_requests = 5$/,
        ].each do |content|
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

    describe '/etc/default/libvirtd' do
      let(:file) { chef_run.template('/etc/default/libvirtd') }

      it 'creates the /etc/default/libvirtd file' do
        expect(chef_run).to create_template(file.name).with(
          owner: 'root',
          group: 'root',
          mode: '644'
        )
      end

      it 'template contents' do
        [
          /^start_libvirtd="yes"$/,
          /^libvirtd_opts="-l"$/,
        ].each do |line|
          expect(chef_run).to render_file(file.name).with_content(line)
        end
      end

      it 'notifies libvirt-bin restart' do
        expect(file).to notify('service[libvirt-bin]').to(:restart)
      end
    end

    it 'does not create /etc/sysconfig/libvirtd' do
      expect(chef_run).not_to create_template '/etc/sysconfig/libvirtd'
    end
  end
end
