# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-compute::nova-common' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) do
      node.set['openstack']['mq'] = {
        'host' => '127.0.0.1'
      }

      runner.converge(described_recipe)
    end

    include_context 'compute_stubs'
    include_examples 'expect_creates_nova_state_dir'
    include_examples 'expect_creates_nova_lock_dir'

    it 'upgrades mysql python package' do
      expect(chef_run).to upgrade_package 'python-mysqldb'
    end

    it 'upgrades nova common package' do
      expect(chef_run).to upgrade_package 'nova-common'
    end

    it 'upgrades memcache python package' do
      expect(chef_run).to upgrade_package 'python-memcache'
    end

    it 'creates the /etc/nova directory' do
      expect(chef_run).to create_directory('/etc/nova').with(
        owner: 'nova',
        group: 'nova',
        mode: 0750
      )
    end

    context 'with logging enabled' do
      before do
        node.set['openstack']['compute']['syslog']['use'] = true
      end

      it 'runs logging recipe if node attributes say to' do
        expect(chef_run).to include_recipe 'openstack-common::logging'
      end
    end

    context 'with logging disabled' do
      before do
        node.set['openstack']['compute']['syslog']['use'] = false
      end

      it "doesn't run logging recipe" do
        expect(chef_run).not_to include_recipe 'openstack-common::logging'
      end
    end

    describe 'nova.conf' do
      let(:file) { chef_run.template('/etc/nova/nova.conf') }

      it 'creates the file' do
        expect(chef_run).to create_template(file.name).with(
          owner: 'nova',
          group: 'nova',
          mode: 0640
        )
      end

      it 'has default set for guestfs debug' do
        expect(chef_run).to render_config_file(file.name).with_section_content('guestfs', /^debug=false$/)
      end

      it 'has no rng_dev_path by default' do
        expect(chef_run).not_to render_config_file(file.name)\
          .with_section_content('libvirt', /^rng_dev_path=/)
      end

      it 'has rng_dev_path config if provided from attribute' do
        node.set['openstack']['compute']['libvirt']['rng_dev_path'] = '/dev/random'
        expect(chef_run).to render_config_file(file.name)\
          .with_section_content('libvirt', %r{^rng_dev_path=/dev/random$})
      end

      it 'has dnsmasq_config_file' do
        expect(chef_run).to render_file(file.name).with_content(/^dnsmasq_config_file=$/)
      end

      it 'has default *_path options set' do
        [%r{^log_dir=/var/log/nova$},
         %r{^state_path=/var/lib/nova$},
         %r{^instances_path=/var/lib/nova/instances$},
         %r{^lock_path=/var/lib/nova/lock$}].each do |line|
          expect(chef_run).to render_file(file.name).with_content(line)
        end
      end

      it 'has default ssl options set' do
        %w(ssl_only=false
           cert=self.pem
           key=).each do |line|
          expect(chef_run).to render_file(file.name).with_content(/^#{line}$/)
        end
      end

      it 'has default quota options set' do
        [/^quota_driver=nova.quota.DbQuotaDriver$/,
         /^quota_security_groups=50$/,
         /^quota_security_group_rules=20$/,
         /^quota_cores=20$/,
         /^quota_fixed_ips=-1$/,
         /^quota_floating_ips=10$/,
         /^quota_injected_file_content_bytes=10240$/,
         /^quota_injected_file_path_length=255$/,
         /^quota_injected_files=5$/,
         /^quota_instances=10$/,
         /^quota_key_pairs=100$/,
         /^quota_metadata_items=128$/,
         /^quota_ram=51200$/
        ].each do |line|
          expect(chef_run).to render_file(file.name).with_content(line)
        end
      end

      it 'has an instance_name_template setting' do
        expect(chef_run).to render_file(file.name).with_content(
          /^instance_name_template=instance-%08x$/)
      end

      it 'has compute driver attributes defaults set' do
        [/^compute_driver=libvirt.LibvirtDriver$/,
         /^compute_manager=nova.compute.manager.ComputeManager$/,
         /^preallocate_images=none$/,
         /^use_cow_images=true$/,
         /^vif_plugging_is_fatal=true$/,
         /^vif_plugging_timeout=300$/,
         /^live_migration_retry_count=30$/].each do |line|
          expect(chef_run).to render_file(file.name).with_content(line)
        end
      end

      it 'has default misc config attributes defaults set' do
        [/^force_raw_images=false$/,
         /^allow_same_net_traffic=true$/,
         /^osapi_max_limit=1000$/,
         /^start_guests_on_host_boot=false$/,
         /^resume_guests_state_on_host_boot=true$/].each do |line|
          expect(chef_run).to render_config_file(file.name).with_section_content('DEFAULT', line)
        end
      end

      it 'has default misc config attributes defaults not set' do
        [/^osapi_compute_link_prefix=/,
         /^osapi_glance_link_prefix=/].each do |line|
          expect(chef_run).not_to render_config_file(file.name).with_section_content('DEFAULT', line)
        end
      end

      it 'does not have compute driver attribute default_ephemeral_format set by default' do
        expect(chef_run).not_to render_file(file.name).with_content(/^default_ephemeral_format=$/)
      end

      it 'allows override for compute driver attribute default_ephemeral_format' do
        node.set['openstack']['compute']['default_ephemeral_format'] = 'someformat'
        expect(chef_run).to render_file(file.name).with_content(/^default_ephemeral_format=someformat$/)
      end

      it 'has default network_allocate_retries set' do
        line = /^network_allocate_retries=0$/
        expect(chef_run).to render_file(file.name).with_content(line)
      end

      it 'has default block_device_allocate_retries set' do
        [/^block_device_allocate_retries=60$/,
         /^block_device_allocate_retries_interval=3$/].each do |line|
          expect(chef_run).to render_config_file(file.name).with_section_content('DEFAULT', line)
        end
      end

      it 'has default resize_confirm_window set' do
        line = /^resize_confirm_window=0$/
        expect(chef_run).to render_file(file.name).with_content(line)
      end

      it 'has default RPC/AMQP options set' do
        [/^rpc_backend=nova.openstack.common.rpc.impl_kombu$/,
         /^rpc_thread_pool_size=64$/,
         /^rpc_conn_pool_size=30$/,
         /^rpc_response_timeout=60$/].each do |line|
          expect(chef_run).to render_file(file.name).with_content(line)
        end
      end

      it 'has default availability zone options set' do
        [/^default_availability_zone=nova$/,
         /^default_schedule_zone=nova/].each do |line|
          expect(chef_run).to render_file(file.name).with_content(line)
        end
      end

      it 'has default compute ip and port options set' do
        [/^osapi_compute_listen=127.0.0.1$/,
         /^osapi_compute_listen_port=8774$/].each do |line|
          expect(chef_run).to render_file(file.name).with_content(line)
        end
      end

      it 'has default ec2 ip and port options set' do
        [/^ec2_listen=127.0.0.1$/,
         /^ec2_listen_port=8773$/].each do |line|
          expect(chef_run).to render_file(file.name).with_content(line)
        end
      end

      it 'has default metadata ip and port options set' do
        [/^metadata_listen=127.0.0.1$/,
         /^metadata_listen_port=8775$/].each do |line|
          expect(chef_run).to render_file(file.name).with_content(line)
        end
      end

      it 'confirms default min value for workers' do
        [/^ec2_workers=/,
         /^osapi_compute_workers=/,
         /^metadata_workers=/,
         /^workers=/].each do |line|
          expect(chef_run).to_not render_file(file.name).with_content(line)
        end
      end

      describe 'allow overrides for workers' do
        it 'has worker overrides' do
          node.set['openstack']['compute']['ec2_workers'] = 123
          node.set['openstack']['compute']['osapi_compute_workers'] = 456
          node.set['openstack']['compute']['metadata_workers'] = 789
          node.set['openstack']['compute']['conductor']['workers'] = 321
          [/^ec2_workers=123$/,
           /^osapi_compute_workers=456$/,
           /^metadata_workers=789$/,
           /^workers=321$/].each do |line|
            expect(chef_run).to render_file(file.name).with_content(line)
          end
        end
      end

      context 'keystone_authtoken' do
        it 'has correct auth_token settings' do
          [
            'auth_uri = http://127.0.0.1:5000/v2.0',
            'identity_uri = http://127.0.0.1:35357/',
            'auth_version = v2.0',
            'admin_tenant_name = service',
            'admin_user = nova',
            'admin_password = nova-pass',
            'signing_dir = /var/cache/nova/api'
          ].each do |line|
            expect(chef_run).to render_config_file(file.name)\
              .with_section_content('keystone_authtoken', /^#{Regexp.quote(line)}$/)
          end
        end
      end

      it 'uses default values for attributes' do
        [
          /^memcached_servers =/,
          /^memcache_security_strategy =/,
          /^memcache_secret_key =/,
          /^cafile =/
        ].each do |line|
          expect(chef_run).not_to render_config_file(file.name)\
            .with_section_content('keystone_authtoken', line)
        end

        [
          /^hash_algorithms = md5$/,
          /^insecure = false$/
        ].each do |line|
          expect(chef_run).to render_config_file(file.name)\
            .with_section_content('keystone_authtoken', line)
        end

        [
          /^ca_file=$/,
          /^cert_file=$/,
          /^key_file=$/
        ].each do |line|
          expect(chef_run).to render_config_file(file.name)\
            .with_section_content('ssl', line)
        end

        [
          /^cafile=$/,
          /^insecure=false/,
          /^catalog_info=volumev2:cinderv2:publicURL$/
        ].each do |line|
          expect(chef_run).to render_config_file(file.name)\
            .with_section_content('cinder', line)
        end

        [
          /^insecure=false$/,
          %r{^api_servers=http://127.0.0.1:9292$},
          /^allowed_direct_url_schemes=$/
        ].each do |line|
          expect(chef_run).to render_config_file(file.name)\
            .with_section_content('glance', line)
        end

        [
          %r{^api_endpoint=http://127.0.0.1:6385$},
          /^admin_username=ironic$/,
          /^admin_password=ironic-pass$/,
          %r{^admin_url=http://127.0.0.1:5000/v2.0$},
          /^admin_tenant_name=service$/
        ].each do |line|
          expect(chef_run).to render_config_file(file.name)\
            .with_section_content('ironic', line)
        end
      end

      it 'sets service_type to neutron' do
        node.set['openstack']['compute']['network']['service_type'] = 'neutron'
        [
          /^insecure=false$/,
          %r{^url=http://127.0.0.1:9696$}
        ].each do |line|
          expect(chef_run).to render_config_file(file.name)\
            .with_section_content('neutron', line)
        end
      end

      it 'sets service_type and insecure and scheme for neutron' do
        node.set['openstack']['compute']['network']['service_type'] = 'neutron'
        node.set['openstack']['compute']['network']['neutron']['insecure'] = true
        node.set['openstack']['endpoints']['network-api']['scheme'] = 'https'
        expect(chef_run).to render_config_file(file.name)\
          .with_section_content('neutron', /^insecure=true$/)
        expect(chef_run).to render_config_file(file.name)\
          .with_section_content('neutron', %r{^url=https://127.0.0.1:9696$})
      end

      it 'sets scheme and insecure for glance' do
        node.set['openstack']['endpoints']['image-api']['scheme'] = 'https'
        node.set['openstack']['compute']['image']['glance_insecure'] = true
        node.set['openstack']['compute']['image']['ssl']['ca_file'] = 'dir/to/path'
        node.set['openstack']['compute']['image']['ssl']['cert_file'] = 'dir/to/path2'
        node.set['openstack']['compute']['image']['ssl']['key_file'] = 'dir/to/path3'

        [
          /^insecure=true$/,
          %r{^api_servers=https://127.0.0.1:9292$}
        ].each do |line|
          expect(chef_run).to render_config_file(file.name)\
            .with_section_content('glance', line)
        end

        [
          %r{^ca_file=dir/to/path$},
          %r{^cert_file=dir/to/path2$},
          %r{^key_file=dir/to/path3$}
        ].each do |line|
          expect(chef_run).to render_config_file(file.name)\
            .with_section_content('ssl', line)
        end
      end

      it 'sets cinder options' do
        node.set['openstack']['compute']['block-storage']['cinder_cafile'] = 'dir/to/path'
        node.set['openstack']['compute']['block-storage']['cinder_insecure'] = true
        node.set['openstack']['compute']['block-storage']['cinder_catalog_info'] = 'volume:cinder:publicURL'

        [
          /^insecure=true$/,
          %r{^cafile=dir/to/path$},
          /^catalog_info=volume:cinder:publicURL$/
        ].each do |line|
          expect(chef_run).to render_config_file(file.name)\
            .with_section_content('cinder', line)
        end
      end

      it 'sets memcached server(s)' do
        node.set['openstack']['compute']['api']['auth']['memcached_servers'] = 'localhost:11211'
        expect(chef_run).to render_config_file(file.name)\
          .with_section_content('keystone_authtoken', /^memcached_servers = localhost:11211$/)
      end

      it 'sets memcache security strategy' do
        node.set['openstack']['compute']['api']['auth']['memcache_security_strategy'] = 'MAC'
        expect(chef_run).to render_config_file(file.name)\
          .with_section_content('keystone_authtoken', /^memcache_security_strategy = MAC$/)
      end

      it 'sets memcache secret key' do
        node.set['openstack']['compute']['api']['auth']['memcache_secret_key'] = '0123456789ABCDEF'
        expect(chef_run).to render_config_file(file.name)\
          .with_section_content('keystone_authtoken', /^memcache_secret_key = 0123456789ABCDEF$/)
      end

      it 'sets cafile' do
        node.set['openstack']['compute']['api']['auth']['cafile'] = 'dir/to/path'
        expect(chef_run).to render_config_file(file.name)\
          .with_section_content('keystone_authtoken', %r{^cafile = dir/to/path$})
      end

      it 'sets token hash algorithms' do
        node.set['openstack']['compute']['api']['auth']['hash_algorithms'] = 'sha2'
        expect(chef_run).to render_config_file(file.name)\
          .with_section_content('keystone_authtoken', /^hash_algorithms = sha2$/)
      end

      it 'sets insecure' do
        node.set['openstack']['compute']['api']['auth']['insecure'] = true
        expect(chef_run).to render_config_file(file.name)\
          .with_section_content('keystone_authtoken', /^insecure = true$/)
      end

      context 'rabbit mq backend' do
        before do
          node.set['openstack']['mq']['compute']['service_type'] = 'rabbitmq'
        end

        describe 'ha rabbit disabled' do
          before do
            # README(galstrom21): There is a order of operations issue here
            #   if you use node.set, these tests will fail.
            node.override['openstack']['mq']['compute']['rabbit']['ha'] = false
          end

          it 'has default rabbit_* options set' do
            [/^amqp_durable_queues=false$/, /^amqp_auto_delete=false$/,
             /^heartbeat_timeout_threshold=0$/, /^heartbeat_rate=2$/,
             /^rabbit_userid=guest$/, /^rabbit_password=mq-pass$/,
             /^rabbit_virtual_host=\/$/, /^rabbit_host=127.0.0.1$/,
             /^rabbit_max_retries=0$/, /^rabbit_retry_interval=1$/,
             /^rabbit_port=5672$/].each do |line|
              expect(chef_run).to render_config_file(file.name).with_section_content('oslo_messaging_rabbit', line)
            end
          end

          it 'does not have ha rabbit options set' do
            [/^rabbit_hosts=/, /^rabbit_ha_queues=/,
             /^ec2_private_dns_show_ip$/].each do |line|
              expect(chef_run).not_to render_config_file(file.name).with_section_content('oslo_messaging_rabbit', line)
            end
          end
        end

        describe 'ha rabbit enabled' do
          before do
            # README(galstrom21): There is a order of operations issue here
            #   if you use node.set, these tests will fail.
            node.override['openstack']['mq']['compute']['rabbit']['ha'] = true
          end

          it 'sets ha rabbit options correctly' do
            [
              /^rabbit_hosts=1.1.1.1:5672,2.2.2.2:5672$/,
              /^rabbit_ha_queues=True$/
            ].each do |line|
              expect(chef_run).to render_config_file(file.name).with_section_content('oslo_messaging_rabbit', line)
            end
          end

          it 'does not have non-ha rabbit options set' do
            [/^rabbit_host=127\.0\.0\.1$/, /^rabbit_port=5672$/].each do |line|
              expect(chef_run).not_to render_config_file(file.name).with_section_content('oslo_messaging_rabbit', line)
            end
          end
        end

        it 'does not have ssl config set' do
          [/^rabbit_use_ssl=/,
           /^kombu_ssl_version=/,
           /^kombu_ssl_keyfile=/,
           /^kombu_ssl_certfile=/,
           /^kombu_ssl_ca_certs=/,
           /^kombu_reconnect_delay=/,
           /^kombu_reconnect_timeout=/].each do |line|
            expect(chef_run).not_to render_config_file(file.name).with_section_content('oslo_messaging_rabbit', line)
          end
        end

        it 'sets ssl config' do
          node.override['openstack']['mq']['compute']['rabbit']['use_ssl'] = true
          node.override['openstack']['mq']['compute']['rabbit']['kombu_ssl_version'] = 'TLSv1.2'
          node.override['openstack']['mq']['compute']['rabbit']['kombu_ssl_keyfile'] = 'keyfile'
          node.override['openstack']['mq']['compute']['rabbit']['kombu_ssl_certfile'] = 'certfile'
          node.override['openstack']['mq']['compute']['rabbit']['kombu_ssl_ca_certs'] = 'certsfile'
          node.override['openstack']['mq']['compute']['rabbit']['kombu_reconnect_delay'] = 123.123
          node.override['openstack']['mq']['compute']['rabbit']['kombu_reconnect_timeout'] = 123
          [/^rabbit_use_ssl=true/,
           /^kombu_ssl_version=TLSv1.2$/,
           /^kombu_ssl_keyfile=keyfile$/,
           /^kombu_ssl_certfile=certfile$/,
           /^kombu_ssl_ca_certs=certsfile$/,
           /^kombu_reconnect_delay=123.123$/,
           /^kombu_reconnect_timeout=123$/].each do |line|
            expect(chef_run).to render_config_file(file.name).with_section_content('oslo_messaging_rabbit', line)
          end
        end
      end

      context 'qpid mq backend' do
        before do
          # README(galstrom21): There is a order of operations issue here
          #   if you use node.set, these tests will fail.
          node.override['openstack']['mq']['compute']['service_type'] = 'qpid'
          node.override['openstack']['mq']['compute']['qpid']['username'] = 'guest'
        end

        it 'has default qpid_* options set' do
          [
            /^amqp_durable_queues=false$/,
            /^amqp_auto_delete=false$/,
            /^qpid_hostname=127.0.0.1$/,
            /^qpid_port=5672$/,
            /^qpid_username=guest$/,
            /^qpid_password=mq-pass$/,
            /^qpid_sasl_mechanisms=$/,
            /^qpid_reconnect_timeout=0$/,
            /^qpid_reconnect_limit=0$/,
            /^qpid_reconnect_interval_min=0$/,
            /^qpid_reconnect_interval_max=0$/,
            /^qpid_reconnect_interval=0$/,
            /^qpid_heartbeat=60$/,
            /^qpid_protocol=tcp$/,
            /^qpid_tcp_nodelay=true$/,
            /^qpid_topology_version=1$/
          ].each do |line|
            expect(chef_run).to render_config_file(file.name).with_section_content('oslo_messaging_qpid', line)
          end
        end
      end

      it 'has monitor options' do
        node.set['openstack']['compute']['config']['compute_monitors'] = ['CustomMonitor']

        [/^compute_available_monitors=nova.compute.monitors.all_monitors$/,
         /^compute_monitors=CustomMonitor$/].each do |line|
          expect(chef_run).to render_file(file.name).with_content(line)
        end
      end

      it 'has default vncserver_* options set' do
        node.set['openstack']['endpoints']['compute-vnc-bind']['bind_interface'] = 'lo'

        [/^vncserver_listen=127.0.1.1$/,
         /^vncserver_proxyclient_address=127.0.1.1$/,
         /^vnc_enabled=true$/,
         /^vnc_keymap=en-us$/].each do |line|
          expect(chef_run).to render_file(file.name).with_content(line)
        end
      end

      it 'has override vncserver_* options set' do
        node.set['openstack']['endpoints']['compute-vnc-bind']['host'] = '1.1.1.1'
        node.set['openstack']['endpoints']['compute-vnc-proxy-bind']['host'] = '2.2.2.2'

        [/^vncserver_listen=1.1.1.1$/,
         /^vncserver_proxyclient_address=2.2.2.2$/].each do |line|
          expect(chef_run).to render_file(file.name).with_content(line)
        end
      end

      it 'has default *vncproxy_* options set' do
        [/^xvpvncproxy_host=127.0.0.1$/,
         /^xvpvncproxy_port=6081$/,
         /^novncproxy_host=127.0.0.1$/,
         /^novncproxy_port=6080$/].each do |line|
          expect(chef_run).to render_file(file.name).with_content(line)
        end
      end

      it 'has default nova.config options set' do
        [/^allow_resize_to_same_host=false$/,
         /^force_dhcp_release=true$/,
         /^mkisofs_cmd=genisoimage$/,
         %r{^injected_network_template=\$pybasedir/nova/virt/interfaces.template$},
         /^flat_injected=false$/,
         /^reserved_host_disk_mb=0$/,
         /^reserved_host_memory_mb=512$/,
         /^use_ipv6=false$/].each do |line|
          expect(chef_run).to render_file(file.name).with_content(line)
        end
      end

      it 'has a force_config_drive setting' do
        chef_run.node.set['openstack']['compute']['config']['force_config_drive'] = 'always'
        expect(chef_run).to render_file(file.name).with_content(
          /^force_config_drive=always$/)
      end

      it 'has a config_drive_format setting' do
        expect(chef_run).to render_file(file.name).with_content(
          /^config_drive_format=iso9660$/)
      end

      it 'has a os_region_name setting' do
        chef_run.node.set['openstack']['node'] = 'RegionOne'
        expect(chef_run).to render_config_file(file.name)\
          .with_section_content('cinder', /^os_region_name=RegionOne$/)
      end

      it 'has a disk_cachemodes setting' do
        chef_run.node.set['openstack']['compute']['config']['disk_cachemodes'] = 'disk:writethrough'
        expect(chef_run).to render_config_file(file.name)\
          .with_section_content('libvirt', /^disk_cachemodes=disk:writethrough$/)
      end

      it 'has use_usb_tablet setting' do
        expect(chef_run).to render_config_file(file.name)\
          .with_section_content('libvirt', /^use_usb_tablet=true$/)
      end

      it 'has keymgr api_class attribute default set' do
        expect(chef_run).to render_config_file(file.name).with_section_content('keymgr', /^api_class=nova.keymgr.conf_key_mgr.ConfKeyManager$/)
      end

      it 'does not have keymgr attribute fixed_key set by default' do
        expect(chef_run).not_to render_file(file.name).with_content(/^fixed_key=$/)
      end

      it 'allow override for keymgr attribute fixed_key' do
        chef_run.node.set['openstack']['compute']['keymgr']['fixed_key'] = '1111111111111111111111111111111111111111111111111111111111111111'
        expect(chef_run).to render_config_file(file.name)\
          .with_section_content('keymgr', /^fixed_key=1111111111111111111111111111111111111111111111111111111111111111$/)
      end

      context 'metering' do
        describe 'metering disabled' do
          it 'leaves default audit options' do
            ['instance_usage_audit=False',
             'instance_usage_audit_period=month'].each do |line|
              expect(chef_run).to render_file(file.name).with_content(line)
            end
          end

          it 'does not configure metering notification' do
            ['notification_driver',
             'notify_on_state_change'].each do |line|
              expect(chef_run).not_to render_file(file.name).with_content(line)
            end
          end
        end

        describe 'notification enabled' do
          before do
            node.override['openstack']['compute']['metering'] = true
          end

          it 'sets audit and notification options correctly' do
            ['notification_driver=nova.openstack.common.notifier.rpc_notifier',
             'notification_driver=ceilometer.compute.nova_notifier',
             'instance_usage_audit=True',
             'instance_usage_audit_period=hour',
             'notify_on_state_change=vm_and_task_state',
             'notification_topics=notifications'
            ].each do |line|
              expect(chef_run).to render_file(file.name).with_content(line)
            end
          end
        end
      end

      context 'libvirt configuration' do
        it 'has default libvirt_* options set' do
          [
            /^use_virtio_for_bridges=true$/,
            /^images_type=default$/,
            /^inject_key=true$/,
            /^inject_password=false$/,
            /^inject_partition=-2$/,
            /^live_migration_bandwidth=0$/,
            /^live_migration_flag=VIR_MIGRATE_UNDEFINE_SOURCE,VIR_MIGRATE_PEER2PEER,VIR_MIGRATE_LIVE,VIR_MIGRATE_PERSIST_DEST$/,
            /^block_migration_flag=VIR_MIGRATE_UNDEFINE_SOURCE, VIR_MIGRATE_PEER2PEER, VIR_MIGRATE_NON_SHARED_INC$/,
            %r{live_migration_uri=qemu\+tcp://%s/system$}
          ].each do |line|
            expect(chef_run).to render_config_file(file.name)\
              .with_section_content('libvirt', line)
          end
        end

        it "the libvirt cpu_mode is none when virt_type is 'qemu'" do
          node.set['openstack']['compute']['libvirt']['virt_type'] = 'qemu'

          expect(chef_run).to render_config_file(file.name)\
            .with_section_content('libvirt', /^cpu_mode=none$/)
        end

        it 'has a configurable inject_key setting' do
          node.set['openstack']['compute']['libvirt']['libvirt_inject_key'] = false

          expect(chef_run).to render_config_file(file.name)\
            .with_section_content('libvirt', /^inject_key=false$/)
        end

        it 'has a configurable inject_password setting' do
          node.set['openstack']['compute']['libvirt']['libvirt_inject_password'] = true

          expect(chef_run).to render_config_file(file.name)\
            .with_section_content('libvirt', /^inject_password=true$/)
        end
      end

      context 'vmware' do
        before do
          # README(galstrom21): There is a order of operations issue here
          #   if you use node.set, these tests will fail.
          node.override['openstack']['compute']['driver'] = 'vmwareapi.VMwareVCDriver'
          # NB(srenatus) this is only one option, the other one is
          #   'vmwareapi.VMwareESXDriver' (see templates/default/nova.conf.erb)
        end

        it 'has vmware config options set' do
          [
            /^host_ip = $/,
            /^host_username = $/,
            /^host_password = vmware_secret_name$/,
            /^task_poll_interval = 0.5$/,
            /^api_retry_count = 10$/,
            /^vnc_port = 5900$/,
            /^vnc_port_total = 10000$/,
            /^use_linked_clone = true$/,
            /^vlan_interface = vmnic0$/,
            /^maximum_objects = 100$/,
            /^integration_bridge = br-int$/
          ].each do |line|
            expect(chef_run).to render_config_file(file.name)\
              .with_section_content('vmware', line)
          end
        end

        it 'has no datastore_regex line' do
          expect(chef_run).not_to render_config_file(file.name)\
            .with_section_content('vmware', 'datastore_regex = ')
        end

        it 'has no wsdl_location line' do
          expect(chef_run).not_to render_config_file(file.name)\
            .with_section_content('vmware', 'wsdl_location = ')
        end
      end

      context 'vmware cluster name' do
        before do
          # README(galstrom21): There is a order of operations issue here
          #   if you use node.set, these tests will fail.
          node.override['openstack']['compute']['driver'] = 'vmwareapi.VMwareVCDriver'
          node.override['openstack']['compute']['vmware']['cluster_name'] = ['cluster1', 'cluster2']
          node.override['openstack']['compute']['vmware']['datastore_regex'] = '*.'
          node.override['openstack']['compute']['vmware']['wsdl_location'] = 'http://127.0.0.1/'
        end

        it 'has multiple cluster name lines' do
          expect(chef_run).to render_config_file(file.name)\
            .with_section_content('vmware', 'cluster_name = cluster1')
          expect(chef_run).to render_config_file(file.name)\
            .with_section_content('vmware', 'cluster_name = cluster2')
        end

        it 'has datastore_regex line' do
          expect(chef_run).to render_config_file(file.name)\
            .with_section_content('vmware', 'datastore_regex = *.')
        end

        it 'has wsdl_location line' do
          expect(chef_run).to render_config_file(file.name)\
            .with_section_content('vmware', 'wsdl_location = http://127.0.0.1/')
        end
      end

      it 'has scheduler options' do
        [/^scheduler_use_baremetal_filters=false$/,
         /^baremetal_scheduler_default_filters=RetryFilter,AvailabilityZoneFilter,ComputeFilter,ComputeCapabilitiesFilter,ImagePropertiesFilter,ExactRamFilter,ExactDiskFilter,ExactCoreFilter$/,
         /^scheduler_manager=nova.scheduler.manager.SchedulerManager$/,
         /^scheduler_driver=nova.scheduler.filter_scheduler.FilterScheduler$/,
         /^scheduler_host_manager=nova.scheduler.host_manager.HostManager$/,
         /^scheduler_available_filters=nova.scheduler.filters.all_filters$/,
         /^scheduler_default_filters=RetryFilter,AvailabilityZoneFilter,RamFilter,ComputeFilter,ComputeCapabilitiesFilter,ImagePropertiesFilter,ServerGroupAntiAffinityFilter,ServerGroupAffinityFilter$/
        ].each do |line|
          expect(chef_run).to render_config_file(file.name).with_section_content('DEFAULT', line)
        end
      end

      it 'sets to use baremetal default attributes' do
        node.set['openstack']['compute']['scheduler']['use_baremetal_filters'] = true

        expect(chef_run.node['openstack']['compute']['driver']).to eq('nova.virt.ironic.IronicDriver')
        expect(chef_run.node['openstack']['compute']['manager']).to eq('ironic.nova.compute.manager.ClusteredComputeManager')
        expect(chef_run.node['openstack']['compute']['scheduler']['scheduler_host_manager']).to eq('nova.scheduler.ironic_host_manager.IronicHostManager')
        expect(chef_run.node['openstack']['compute']['config']['ram_allocation_ratio']).to eq(1.0)
        expect(chef_run.node['openstack']['compute']['config']['reserved_host_memory_mb']).to eq(0)

        [
          /^scheduler_use_baremetal_filters=true$/,
          /^compute_driver=nova.virt.ironic.IronicDriver$/,
          /^compute_manager=ironic.nova.compute.manager.ClusteredComputeManager$/,
          /^scheduler_host_manager=nova.scheduler.ironic_host_manager.IronicHostManager$/,
          /^ram_allocation_ratio=1.0$/,
          /^reserved_host_memory_mb=0$/
        ].each do |line|
          expect(chef_run).to render_config_file(file.name).with_section_content('DEFAULT', line)
        end
      end

      it 'has disk_allocation_ratio when the right filter is set' do
        node.set['openstack']['compute']['scheduler']['default_filters'] = %w(
          RetryFilter
          AvailabilityZoneFilter
          RamFilter
          ComputeFilter
          ComputeCapabilitiesFilter
          ImagePropertiesFilter
          ServerGroupAntiAffinityFilter
          ServerGroupAffinityFilter)
        expect(chef_run).not_to render_file(file.name).with_content(
          'disk_allocation_ratio=1.0')
        expect(chef_run).to render_file(file.name).with_content(
          'cpu_allocation_ratio=16.0')
        expect(chef_run).to render_file(file.name).with_content(
          'ram_allocation_ratio=1.5')
      end

      it 'has no auto_assign_floating_ip' do
        node.set['openstack']['compute']['network']['service_type'] = 'neutron'
        expect(chef_run).not_to render_file(file.name).with_content(
          'auto_assign_floating_ip=false')
      end

      it 'templates misc_nova array correctly' do
        node.set['openstack']['compute']['misc_nova'] = ['MISC_OPTION', 'FOO']
        expect(chef_run).to render_file(file.name).with_content(
          'MISC_OPTION')
      end

      context 'rbd backend' do
        before do
          node.set['openstack']['compute']['libvirt']['images_type'] = 'rbd'
        end

        describe 'default rbd settings' do
          it 'sets the libvirt * options correctly' do
            [
              /^images_type=rbd$/,
              /^images_rbd_pool=instances$/,
              %r{^images_rbd_ceph_conf=/etc/ceph/ceph.conf$},
              /^rbd_user=cinder$/,
              /^rbd_secret_uuid=00000000-0000-0000-0000-000000000000$/
            ].each do |line|
              expect(chef_run).to render_config_file(file.name)\
                .with_section_content('libvirt', line)
            end
          end
        end

        describe 'override rbd settings' do
          before do
            node.set['openstack']['compute']['libvirt']['images_type'] = 'rbd'
            node.set['openstack']['compute']['libvirt']['rbd']['nova']['pool'] = 'myrbd'
            node.set['openstack']['compute']['libvirt']['rbd']['ceph_conf'] = '/etc/myceph/ceph.conf'
          end

          it 'sets the overridden libvirt options correctly' do
            [
              /^images_type=rbd$/,
              /^images_rbd_pool=myrbd$/,
              %r{^images_rbd_ceph_conf=/etc/myceph/ceph.conf$}
            ].each do |line|
              expect(chef_run).to render_config_file(file.name)\
                .with_section_content('libvirt', line)
            end
          end
        end
      end

      context 'lvm backend' do
        before do
          node.set['openstack']['compute']['libvirt']['images_type'] = 'lvm'
          node.set['openstack']['compute']['libvirt']['volume_group'] = 'instances'
        end

        it 'sets the lvm options correctly' do
          [
            /^images_type=lvm$/,
            /^images_volume_group=instances$/,
            /^sparse_logical_volumes=false$/
          ].each do |line|
            expect(chef_run).to render_config_file(file.name)\
              .with_section_content('libvirt', line)
          end
        end

        describe 'override settings' do
          before do
            node.set['openstack']['compute']['libvirt']['images_type'] = 'lvm'
            node.set['openstack']['compute']['libvirt']['volume_group'] = 'instances'
            node.set['openstack']['compute']['libvirt']['sparse_logical_volumes'] = true
            node.set['openstack']['compute']['libvirt']['cpu_mode'] = 'none'
          end

          it 'sets the overridden lvm options correctly' do
            [
              /^images_type=lvm$/,
              /^images_volume_group=instances$/,
              /^sparse_logical_volumes=true$/,
              /^cpu_mode=none$/
            ].each do |line|
              expect(chef_run).to render_config_file(file.name)\
                .with_section_content('libvirt', line)
            end
          end
        end
      end

      it 'sets the upgrade levels' do
        node.set['openstack']['compute']['upgrade_levels'] = { 'compute' => 'juno',
                                                               'cert' => '3.0',
                                                               'network' => 'havana'
                                                             }
        node['openstack']['compute']['upgrade_levels'].each do |key, val|
          expect(chef_run).to render_config_file(file.name).with_section_content('upgrade_levels', /^#{key} = #{val}$/)
        end
      end

      context 'image file systems' do
        it 'no image_file_url section by default' do
          expect(chef_run).not_to render_file(file.name).with_content(/^\[image_file_url/)
        end

        it 'build image_file_url sections' do
          node.set['openstack']['compute']['image']['filesystems'] = {
            'some_fs' => {
              'id' => '00000000-0000-0000-0000-000000000000',
              'mountpoint' => '/mount/some_fs/images'
            },
            'another_fs' => {
              'id' => '1111111-1111-1111-1111-1111111111111',
              'mountpoint' => '/mount/another_fs/images'
            }
          }
          [
            /^id=00000000-0000-0000-0000-000000000000$/,
            %r{^mountpoint=/mount/some_fs/images$}
          ].each do |line|
            expect(chef_run).to render_config_file(file.name).with_section_content('image_file_url:some_fs', line)
          end
          [
            /^id=1111111-1111-1111-1111-1111111111111$/,
            %r{^mountpoint=/mount/another_fs/images$}
          ].each do |line|
            expect(chef_run).to render_config_file(file.name).with_section_content('image_file_url:another_fs', line)
          end

          line = 'filesystems=some_fs,another_fs'
          expect(chef_run).to render_config_file(file.name).with_section_content('image_file_url', line)
        end
      end

      context 'serial console' do
        it 'sets default serial console options set' do
          [
            /^enabled=False$/,
            %r{base_url=ws://127.0.0.1:6083/$},
            /^port_range=10000:20000$/,
            /^proxyclient_address=127.0.0.1$/
          ].each do |line|
            expect(chef_run).to render_config_file(file.name)\
              .with_section_content('serial_console', line)
          end
        end

        it 'sets overide serial console options set' do
          node.set['openstack']['endpoints']['compute-serial-console-bind']['bind_interface'] = 'lo'
          node.set['openstack']['endpoints']['compute-serial-proxy']['scheme'] = 'wss'
          node.set['openstack']['endpoints']['compute-serial-proxy']['host'] = '1.1.1.1'
          node.set['openstack']['endpoints']['compute-serial-proxy']['port'] = '6082'
          node.set['openstack']['compute']['serial_console']['enable'] = 'True'
          node.set['openstack']['compute']['serial_console']['port_range'] = '11000:15000'

          [
            /^enabled=True$/,
            %r{base_url=wss://1.1.1.1:6082/$},
            /^port_range=11000:15000$/,
            /^proxyclient_address=127.0.1.1$/
          ].each do |line|
            expect(chef_run).to render_config_file(file.name)\
              .with_section_content('serial_console', line)
          end
        end
      end
    end

    describe 'rootwrap.conf' do
      let(:file) { chef_run.template('/etc/nova/rootwrap.conf') }

      it 'creates the /etc/nova/rootwrap.conf file' do
        expect(chef_run).to create_template(file.name).with(
          user: 'root',
          group: 'root',
          mode: 0644
        )
      end

      context 'template contents' do
        it 'shows the custom banner' do
          node.set['openstack']['compute']['custom_template_banner'] = 'banner'

          expect(chef_run).to render_file(file.name).with_content(/^banner$/)
        end

        it 'sets the default attributes' do
          [
            %r{^filters_path=/etc/nova/rootwrap.d,/usr/share/nova/rootwrap$},
            %r{^exec_dirs=/sbin,/usr/sbin,/bin,/usr/bin$},
            /^use_syslog=False$/,
            /^syslog_log_facility=syslog$/,
            /^syslog_log_level=ERROR$/
          ].each do |line|
            expect(chef_run).to render_file(file.name).with_content(line)
          end
        end
      end
    end

    it 'enables nova login' do
      expect(chef_run).to run_execute('usermod -s /bin/sh nova')
    end
  end
end
