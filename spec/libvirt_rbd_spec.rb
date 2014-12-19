# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-compute::libvirt_rbd' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::Runner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) do
      node.set['ceph']['config']['fsid'] = '00000000-0000-0000-0000-000000000000'
      node.set['openstack']['compute']['libvirt']['volume_backend'] = 'rbd'

      runner.converge(described_recipe)
    end

    include_context 'compute_stubs'

    it 'includes the ceph recipe' do
      expect(chef_run).to include_recipe('ceph')
    end

    describe 'if there was no secret with this uuid defined' do
      let(:file) { chef_run.template('/tmp/secret.xml') }

      it 'defines the secret' do
        expect(chef_run).to run_execute('virsh secret-define --file /tmp/secret.xml')
      end

      it 'sets the secret value to the password' do
        expect(chef_run).to run_execute('virsh secret-set-value --secret 00000000-0000-0000-0000-000000000000 --base64 $(ceph-authtool -p -n client.cinder /etc/ceph/ceph.client.cinder.keyring)')
      end

      it 'creates the temporary secret xml file' do
        expect(chef_run).to create_template('/tmp/secret.xml').with(
          owner: 'root',
          group: 'root',
          mode: '00600'
        )
      end

      it 'deletes the temporary secret xml file' do
        expect(chef_run).to delete_file('/tmp/secret.xml')
      end
    end
  end
end
