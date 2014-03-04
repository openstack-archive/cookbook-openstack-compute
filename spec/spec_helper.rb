# encoding: UTF-8

require 'chefspec'
require 'chefspec/berkshelf'
require 'chef/application'
require 'securerandom'

LOG_LEVEL = :fatal
SUSE_OPTS = {
  platform: 'suse',
  version: '11.03',
  log_level: LOG_LEVEL
}
REDHAT_OPTS = {
  platform: 'redhat',
  version: '6.3',
  log_level: LOG_LEVEL
}
UBUNTU_OPTS = {
  platform: 'ubuntu',
  version: '12.04',
  log_level: LOG_LEVEL
}

shared_context 'compute_stubs' do
  before do
    Chef::Recipe.any_instance.stub(:rabbit_servers)
      .and_return '1.1.1.1:5672,2.2.2.2:5672'
    Chef::Recipe.any_instance.stub(:address_for)
      .with('lo')
      .and_return '127.0.1.1'
    Chef::Recipe.any_instance.stub(:search_for)
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
    Chef::Recipe.any_instance.stub(:secret)
      .with('secrets', 'openstack_identity_bootstrap_token')
      .and_return('bootstrap-token')
    Chef::Recipe.any_instance.stub(:secret)
      .with('secrets', 'neutron_metadata_secret')
      .and_return('metadata-secret')
    Chef::Recipe.any_instance.stub(:secret) # this is the rbd_uuid default name
      .with('secrets', 'rbd_secret_uuid')
      .and_return '00000000-0000-0000-0000-000000000000'
    Chef::Recipe.any_instance.stub(:get_password)
      .with('db', anything)
      .and_return('')
    Chef::Recipe.any_instance.stub(:get_password)
      .with('user', 'guest')
      .and_return('mq-pass')
    Chef::Recipe.any_instance.stub(:get_password)
      .with('user', 'admin')
      .and_return('admin')
    Chef::Recipe.any_instance.stub(:get_password)
      .with('service', 'openstack-compute')
      .and_return('nova-pass')
    Chef::Recipe.any_instance.stub(:get_password)
      .with('service', 'openstack-network')
      .and_return('neutron-pass')
    Chef::Recipe.any_instance.stub(:get_password)
      .with('service', 'rbd_block_storage')
      .and_return 'cinder-rbd-pass'
    Chef::Recipe.any_instance.stub(:memcached_servers).and_return []
    Chef::Recipe.any_instance.stub(:system)
      .with("grub2-set-default 'openSUSE GNU/Linux, with Xen hypervisor'")
      .and_return(true)
    Chef::Application.stub(:fatal!)
    SecureRandom.stub(:hex) { 'ad3313264ea51d8c6a3d1c5b140b9883' }
    stub_command('nova-manage network list | grep 192.168.100.0/24').and_return(false)
    stub_command('nova-manage network list | grep 192.168.200.0/24').and_return(false)
    stub_command("nova-manage floating list |grep -E '.*([0-9]{1,3}[.]){3}[0-9]{1,3}*'").and_return(false)
    stub_command('virsh net-list | grep -q default').and_return(true)
    stub_command('ovs-vsctl br-exists br-int').and_return(true)
    stub_command('ovs-vsctl br-exists br-tun').and_return(true)
    stub_command('virsh secret-list | grep 00000000-0000-0000-0000-000000000000').and_return(false)
    stub_command("virsh secret-get-value 00000000-0000-0000-0000-000000000000 | grep 'cinder-rbd-pass'").and_return(false)
  end
end

shared_examples 'expect_runs_nova_common_recipe' do
  it 'installs nova-common' do
    expect(chef_run).to include_recipe 'openstack-compute::nova-common'
  end
end

shared_examples 'expect_installs_python_keystone' do
  it 'installs python-keystone' do
    expect(chef_run).to upgrade_package 'python-keystone'
  end
end

shared_examples 'expect_creates_nova_lock_dir' do
  it 'creates the /var/lock/nova directory' do
    expect(chef_run).to create_directory('/var/lock/nova').with(
      user: 'nova',
      group: 'nova',
      mode: 0700
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

    it 'template contents' do
      pending 'TODO: implement'
    end

    it 'notifies #{service} #{action}' do
      expect(file).to notify(service).to(action)
    end
  end
end

# README(galstrom21): This will remove any coverage warnings from
#   dependent cookbooks
ChefSpec::Coverage.filters << '*/openstack-compute'

at_exit { ChefSpec::Coverage.report! }
