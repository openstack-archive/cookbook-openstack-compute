# encoding: UTF-8

require 'chefspec'
require 'chefspec/berkshelf'

ChefSpec::Coverage.start! { add_filter 'openstack-compute' }

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
    Chef::Recipe.any_instance.stub(:get_secret)
      .with('openstack_identity_bootstrap_token')
      .and_return('bootstrap-token')
    Chef::Recipe.any_instance.stub(:get_secret)
      .with('neutron_metadata_secret')
      .and_return('metadata-secret')
    Chef::Recipe.any_instance.stub(:get_secret) # this is the rbd_uuid default name
      .with('rbd_secret_uuid')
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

shared_examples 'expect_installs_python_keystoneclient' do
  it 'installs python-keystoneclient' do
    expect(chef_run).to upgrade_package 'python-keystoneclient'
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

    describe 'keystone auth token' do
      it 'has auth_uri' do
        expect(chef_run).to render_file(file.name).with_content(
          /^#{Regexp.quote('auth_uri = http://127.0.0.1:5000/v2.0')}$/)
      end

      it 'has auth_host' do
        expect(chef_run).to render_file(file.name).with_content(
          /^#{Regexp.quote('auth_host = 127.0.0.1')}$/)
      end

      it 'has auth_port' do
        expect(chef_run).to render_file(file.name).with_content(
          /^auth_port = 35357$/)
      end

      it 'has auth_protocol' do
        expect(chef_run).to render_file(file.name).with_content(
          /^auth_protocol = http$/)
      end

      it 'has auth_version' do
        expect(chef_run).to render_file(file.name).with_content(
          /^auth_version = v2.0$/)
      end

      it 'has admin_tenant_name' do
        expect(chef_run).to render_file(file.name).with_content(
          /^admin_tenant_name = service$/)
      end

      it 'has admin_user' do
        expect(chef_run).to render_file(file.name).with_content(
          /^admin_user = nova$/)
      end

      it 'has admin_password' do
        expect(chef_run).to render_file(file.name).with_content(
          /^admin_password = nova-pass$/)
      end

      it 'has signing_dir' do
        expect(chef_run).to render_file(file.name).with_content(
          /^#{Regexp.quote('signing_dir = /var/cache/nova/api')}$/)
      end
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
