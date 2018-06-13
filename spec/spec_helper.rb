# encoding: UTF-8

require 'chefspec'
require 'chefspec/berkshelf'

ChefSpec::Coverage.start! { add_filter 'openstack-compute' }

require 'chef/application'
require 'securerandom'

RSpec.configure do |config|
  config.color = true
  config.formatter = :documentation
  config.log_level = :fatal
end

REDHAT_OPTS = {
  platform: 'redhat',
  version: '7.4',
}.freeze
UBUNTU_OPTS = {
  platform: 'ubuntu',
  version: '16.04',
  file_cache_path: Chef::Config[:file_cache_path],
}.freeze

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
              'admin_user' => 'admin',
            },
          },
        }]
      )
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('token', 'openstack_identity_bootstrap_token')
      .and_return('bootstrap-token')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('token', 'neutron_metadata_secret')
      .and_return('metadata-secret')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('token', 'openstack_vmware_secret_name')
      .and_return 'vmware_secret_name'
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('db', 'nova')
      .and_return('nova_db_pass')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('db', 'nova_api')
      .and_return('nova_api_db_pass')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('db', 'nova_cell0')
      .and_return('nova_cell0_db_pass')
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
      .with('service', 'openstack-placement')
      .and_return('placement-pass')
    allow_any_instance_of(Chef::Recipe).to receive(:rabbit_transport_url)
      .with('compute')
      .and_return('rabbit://guest:mypass@127.0.0.1:5672')
    allow_any_instance_of(Chef::Recipe).to receive(:memcached_servers).and_return []
    allow(Chef::Application).to receive(:fatal!)
    allow(SecureRandom).to receive(:hex).and_return('ad3313264ea51d8c6a3d1c5b140b9883')
    # stub_command('nova-manage network list | grep 192.168.100.0/24').and_return(false)
    # stub_command('nova-manage network list | grep 192.168.200.0/24').and_return(false)
    # stub_command("nova-manage floating list |grep -E '.*([0-9]{1,3}[.]){3}[0-9]{1,3}*'").and_return(false)
    stub_command('/usr/sbin/apache2 -t').and_return(true)
    stub_command('virsh net-list | grep -q default').and_return(true)
    stub_command('ovs-vsctl br-exists br-int').and_return(true)
    stub_command('ovs-vsctl br-exists br-tun').and_return(true)
    stub_command('nova-manage api_db sync').and_return(true)
    stub_command('nova-manage cell_v2 map_cell0 --database_connection mysql+pymysql://nova_cell0:mypass@127.0.0.1/nova_cell0?charset=utf8').and_return(true)
    stub_command('nova-manage cell_v2 create_cell --verbose --name cell1').and_return(true)
    stub_command('nova-manage cell_v2 list_cells | grep -q cell0').and_return(false)
    stub_command('nova-manage cell_v2 list_cells | grep -q cell1').and_return(false)
    stub_command('nova-manage cell_v2 discover_hosts').and_return(true)
  end
end

shared_examples 'expect_volume_packages' do
  it 'upgrades volume utils packages' do
    %w(sysfsutils sg3_utils device-mapper-multipath).each do |pkg|
      expect(chef_run).to upgrade_package(pkg)
    end
  end
end

shared_examples 'expect_runs_nova_common_recipe' do
  it 'includes nova-common' do
    expect(chef_run).to include_recipe 'openstack-compute::nova-common'
  end
end

shared_examples 'expect_runs_nova_cell_recipe' do
  it 'includes _nova_cell' do
    expect(chef_run).to include_recipe 'openstack-compute::_nova_cell'
  end
end

shared_examples 'expect_creates_nova_state_dir' do
  it 'creates the /var/lib/nova/lock directory' do
    expect(chef_run).to create_directory('/var/lib/nova').with(
      user: 'nova',
      group: 'nova',
      mode: 0o755
    )
  end
end

shared_examples 'expect_creates_nova_lock_dir' do
  it 'creates the /var/lib/nova/lock directory' do
    expect(chef_run).to create_directory('/var/lib/nova/lock').with(
      user: 'nova',
      group: 'nova',
      mode: 0o755
    )
  end
end

shared_examples 'expect_creates_nova_instances_dir' do
  it 'creates the /var/lib/nova/lock directory' do
    expect(chef_run).to create_directory('/var/lib/nova/instances').with(
      user: 'nova',
      group: 'nova',
      mode: 0o755
    )
  end
end

shared_examples 'expect_creates_api_paste_template' do
  let(:file) { chef_run.template('/etc/nova/api-paste.ini') }
  it 'creates api-paste.ini' do
    expect(chef_run).to create_template('/etc/nova/api-paste.ini').with(
      user: 'nova',
      group: 'nova',
      mode: 0o644
    )
  end

  context 'template contents' do
    it 'pastes the misc attributes' do
      node.set['openstack']['compute']['misc_paste'] = %w(paste1 paste2)
      expect(chef_run).to render_file(file.name)
        .with_content(/^paste1$/).with_content(/^paste2$/)
    end
  end
end
