# encoding: UTF-8

require 'chefspec'
require 'chefspec/berkshelf'

ChefSpec::Coverage.start! { add_filter 'openstack-compute' }

require 'chef/application'
require 'securerandom'

LOG_LEVEL = :fatal
SUSE_OPTS = {
  platform: 'suse',
  version: '11.3',
  log_level: LOG_LEVEL
}
REDHAT_OPTS = {
  platform: 'redhat',
  version: '7.0',
  log_level: LOG_LEVEL
}
UBUNTU_OPTS = {
  platform: 'ubuntu',
  version: '14.04',
  log_level: LOG_LEVEL
}

shared_context 'compute_stubs' do
  before do
    allow_any_instance_of(Chef::Recipe).to receive(:rabbit_servers)
      .and_return '1.1.1.1:5672,2.2.2.2:5672'
    allow_any_instance_of(Chef::Recipe).to receive(:address_for)
      .with('lo')
      .and_return '127.0.1.1'
    allow_any_instance_of(Chef::Recipe).to receive(:search_for)
      .with('os-identity').and_return(
        [{
          'openstack' => {
            'identity' => {
              'admin_tenant_name' => 'admin',
              'admin_user' => 'admin'
            }
          }
        }]
      )
    allow_any_instance_of(Chef::Recipe).to receive(:get_secret)
      .with('openstack_identity_bootstrap_token')
      .and_return('bootstrap-token')
    allow_any_instance_of(Chef::Recipe).to receive(:get_secret)
      .with('neutron_metadata_secret')
      .and_return('metadata-secret')
    allow_any_instance_of(Chef::Recipe).to receive(:get_secret) # this is the rbd_uuid default name
      .with('rbd_secret_uuid')
      .and_return '00000000-0000-0000-0000-000000000000'
    allow_any_instance_of(Chef::Recipe).to receive(:get_secret)
      .with('openstack_vmware_secret_name')
      .and_return 'vmware_secret_name'
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('db', anything)
      .and_return('')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('user', 'guest')
      .and_return('mq-pass')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('user', 'admin')
      .and_return('admin')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('service', 'openstack-compute')
      .and_return('nova-pass')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('service', 'openstack-network')
      .and_return('neutron-pass')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('service', 'rbd_block_storage')
      .and_return 'cinder-rbd-pass'
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('service', 'openstack-bare-metal')
      .and_return 'ironic-pass'
    allow_any_instance_of(Chef::Recipe).to receive(:memcached_servers).and_return []
    allow_any_instance_of(Chef::Recipe).to receive(:system)
      .with("grub2-set-default 'openSUSE GNU/Linux, with Xen hypervisor'")
      .and_return(true)
    allow(Chef::Application).to receive(:fatal!)
    allow(SecureRandom).to receive(:hex).and_return('ad3313264ea51d8c6a3d1c5b140b9883')
    stub_command('nova-manage network list | grep 192.168.100.0/24').and_return(false)
    stub_command('nova-manage network list | grep 192.168.200.0/24').and_return(false)
    stub_command("nova-manage floating list |grep -E '.*([0-9]{1,3}[.]){3}[0-9]{1,3}*'").and_return(false)
    stub_command('virsh net-list | grep -q default').and_return(true)
    stub_command('ovs-vsctl br-exists br-int').and_return(true)
    stub_command('ovs-vsctl br-exists br-tun').and_return(true)
    stub_command('virsh secret-list | grep 00000000-0000-0000-0000-000000000000').and_return(false)
    stub_command('virsh secret-set-value --secret 00000000-0000-0000-0000-000000000000 --base64 $(ceph-authtool -p -n client.cinder /etc/ceph/ceph.client.cinder.keyring)').and_return(false)
    stub_command('virsh secret-get-value 00000000-0000-0000-0000-000000000000 | grep $(ceph-authtool -p -n client.cinder /etc/ceph/ceph.client.cinder.keyring)').and_return(false)
  end
end

shared_examples 'expect_volume_packages' do
  it 'upgrades volume utils packages' do
    %w(sysfsutils sg3_utils multipath-tools).each do |pkg|
      expect(chef_run).to upgrade_package(pkg)
    end
  end
end

shared_examples 'expect_runs_nova_common_recipe' do
  it 'includes nova-common' do
    expect(chef_run).to include_recipe 'openstack-compute::nova-common'
  end
end

shared_examples 'expect_upgrades_python_keystoneclient' do
  it 'upgrades python-keystoneclient' do
    expect(chef_run).to upgrade_package 'python-keystoneclient'
  end
end

shared_examples 'expect_creates_nova_state_dir' do
  it 'creates the /var/lib/nova/lock directory' do
    expect(chef_run).to create_directory('/var/lib/nova').with(
      user: 'nova',
      group: 'nova',
      mode: 0755
    )
  end
end

shared_examples 'expect_creates_nova_lock_dir' do
  it 'creates the /var/lib/nova/lock directory' do
    expect(chef_run).to create_directory('/var/lib/nova/lock').with(
      user: 'nova',
      group: 'nova',
      mode: 0755
    )
  end
end

shared_examples 'expect_creates_nova_instances_dir' do
  it 'creates the /var/lib/nova/lock directory' do
    expect(chef_run).to create_directory('/var/lib/nova/instances').with(
      user: 'nova',
      group: 'nova',
      mode: 0755
    )
  end
end

def expect_creates_api_paste(service, action = :restart) # rubocop:disable MethodLength
  describe '/etc/nova/api-paste.ini' do
    let(:file) { chef_run.template('/etc/nova/api-paste.ini') }
    it 'creates api-paste.ini' do
      expect(chef_run).to create_template(file.name).with(
        user: 'nova',
        group: 'nova',
        mode: 0644
      )
    end

    context 'template contents' do
      context 'ec2 enabled' do
        before do
          node.set['openstack']['compute']['enabled_apis'] = %w(ec2)
        end

        it 'sets the pipeline attribute' do
          expect(chef_run).to render_file(file.name)
                               .with_content(/^pipeline = ec2faultwrap logrequest metaapp$/)
        end

        it 'sets ec2 attributes' do
          expect(chef_run).to render_file(file.name)
                               .with_content(/^\[composite:ec2\]$/)
        end
      end

      it 'sets the pipeline attribute when ec2 api is disabled' do
        node.set['openstack']['compute']['enabled_apis'] = []
        expect(chef_run).to render_file(file.name)
                             .with_content(/^pipeline = faultwrap metaapp$/)
      end

      it 'pastes the misc attributes' do
        node.set['openstack']['compute']['misc_paste'] = %w(paste1 paste2)
        expect(chef_run).to render_file(file.name)
                             .with_content(/^paste1$/).with_content(/^paste2$/)
      end
    end

    it 'notifies #{service} #{action}' do
      expect(file).to notify(service).to(action)
    end
  end
end
