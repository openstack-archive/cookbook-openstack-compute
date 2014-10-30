# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-compute::nova-common' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::Runner.new(UBUNTU_OPTS) }
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

      it 'has no rng_dev_path by default' do
        expect(chef_run).not_to render_file(file.name).with_content(/^rng_dev_path=/)
      end

      it 'has rng_dev_path config if provided from attribute' do
        node.set['openstack']['compute']['libvirt']['rng_dev_path'] = '/dev/random'
        expect(chef_run).to render_file(file.name).with_content(%r{^rng_dev_path=/dev/random$})
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
        %W(ssl_only=false
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

      it 'has default resize_confirm_window set' do
        line = /^resize_confirm_window=0$/
        expect(chef_run).to render_file(file.name).with_content(line)
      end

      it 'has default RPC/AMQP options set' do
        [/^rpc_backend=nova.openstack.common.rpc.impl_kombu$/,
         /^rpc_thread_pool_size=64$/,
         /^rpc_conn_pool_size=30$/,
         /^rpc_response_timeout=60$/,
         /^amqp_durable_queues=false$/,
         /^amqp_auto_delete=false$/].each do |line|
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
        [/^metadata_listen=0.0.0.0$/,
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
            'auth_host = 127.0.0.1',
            'auth_port = 35357',
            'auth_protocol = http',
            'auth_version = v2.0',
            'admin_tenant_name = service',
            'admin_user = nova',
            'admin_password = nova-pass',
            'signing_dir = /var/cache/nova/api'
          ].each do |line|
            expect(chef_run).to render_file(file.name).with_content(
              /^#{Regexp.quote(line)}$/)
          end
        end
      end

      it 'uses default values for attributes' do
        expect(chef_run).not_to render_file(file.name).with_content(
          /^memcached_servers =/)
        expect(chef_run).not_to render_file(file.name).with_content(
          /^memcache_security_strategy =/)
        expect(chef_run).not_to render_file(file.name).with_content(
          /^memcache_secret_key =/)
        expect(chef_run).not_to render_file(file.name).with_content(
          /^cafile =/)
        expect(chef_run).to render_file(file.name).with_content(/^ca_file=$/)
        expect(chef_run).to render_file(file.name).with_content(/^cert_file=$/)
        expect(chef_run).to render_file(file.name).with_content(/^key_file=$/)
        expect(chef_run).to render_file(file.name).with_content(/^cinder_ca_certificates_file=$/)
        expect(chef_run).to render_file(file.name).with_content(/^cinder_api_insecure=false/)
        expect(chef_run).to render_file(file.name).with_content(/^hash_algorithms = md5$/)
        expect(chef_run).to render_file(file.name).with_content(/^insecure = false$/)
        expect(chef_run).to render_file(file.name).with_content(/^glance_api_insecure=false$/)
        expect(chef_run).to render_file(file.name).with_content(%r{^glance_api_servers=http://127.0.0.1:9292$})
      end

      it 'sets service_type to neutron' do
        node.set['openstack']['compute']['network']['service_type'] = 'neutron'
        expect(chef_run).to render_file(file.name).with_content(/^neutron_api_insecure=false$/)
        expect(chef_run).to render_file(file.name).with_content(%r{^neutron_url=http://127.0.0.1:9696$})
      end

      it 'sets service_type and insecure and scheme for neutron' do
        node.set['openstack']['compute']['network']['service_type'] = 'neutron'
        node.set['openstack']['compute']['network']['neutron']['api_insecure'] = true
        node.set['openstack']['endpoints']['network-api']['scheme'] = 'https'
        expect(chef_run).to render_file(file.name).with_content(/^neutron_api_insecure=true$/)
        expect(chef_run).to render_file(file.name).with_content(%r{^neutron_url=https://127.0.0.1:9696$})
      end

      it 'sets scheme and insecure for glance' do
        node.set['openstack']['endpoints']['image-api']['scheme'] = 'https'
        node.set['openstack']['compute']['image']['glance_api_insecure'] = true
        node.set['openstack']['compute']['image']['ssl']['ca_file'] = 'dir/to/path'
        node.set['openstack']['compute']['image']['ssl']['cert_file'] = 'dir/to/path2'
        node.set['openstack']['compute']['image']['ssl']['key_file'] = 'dir/to/path3'
        expect(chef_run).to render_file(file.name).with_content(/^glance_api_insecure=true$/)
        expect(chef_run).to render_file(file.name).with_content(%r{^glance_api_servers=https://127.0.0.1:9292$})
        expect(chef_run).to render_file(file.name).with_content(%r{^ca_file=dir/to/path$})
        expect(chef_run).to render_file(file.name).with_content(%r{^cert_file=dir/to/path2$})
        expect(chef_run).to render_file(file.name).with_content(%r{^key_file=dir/to/path3$})
      end

      it 'sets cinder options' do
        node.set['openstack']['compute']['block-storage']['cinder_ca_certificates_file'] = 'dir/to/path'
        node.set['openstack']['compute']['block-storage']['cinder_api_insecure'] = true
        expect(chef_run).to render_file(file.name).with_content(/^cinder_api_insecure=true$/)
        expect(chef_run).to render_file(file.name).with_content(%r{^cinder_ca_certificates_file=dir/to/path$})
      end

      it 'sets memcached server(s)' do
        node.set['openstack']['compute']['api']['auth']['memcached_servers'] = 'localhost:11211'
        expect(chef_run).to render_file(file.name).with_content(/^memcached_servers = localhost:11211$/)
      end

      it 'sets memcache security strategy' do
        node.set['openstack']['compute']['api']['auth']['memcache_security_strategy'] = 'MAC'
        expect(chef_run).to render_file(file.name).with_content(/^memcache_security_strategy = MAC$/)
      end

      it 'sets memcache secret key' do
        node.set['openstack']['compute']['api']['auth']['memcache_secret_key'] = '0123456789ABCDEF'
        expect(chef_run).to render_file(file.name).with_content(/^memcache_secret_key = 0123456789ABCDEF$/)
      end

      it 'sets cafile' do
        node.set['openstack']['compute']['api']['auth']['cafile'] = 'dir/to/path'
        expect(chef_run).to render_file(file.name).with_content(%r{^cafile = dir/to/path$})
      end

      it 'sets token hash algorithms' do
        node.set['openstack']['compute']['api']['auth']['hash_algorithms'] = 'sha2'
        expect(chef_run).to render_file(file.name).with_content(/^hash_algorithms = sha2$/)
      end

      it 'sets insecure' do
        node.set['openstack']['compute']['api']['auth']['insecure'] = true
        expect(chef_run).to render_file(file.name).with_content(/^insecure = true$/)
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
            [/^rabbit_userid=guest$/, /^rabbit_password=mq-pass$/,
             /^rabbit_virtual_host=\/$/, /^rabbit_host=127.0.0.1$/,
             /^rabbit_port=5672$/, /^rabbit_use_ssl=false$/].each do |line|
              expect(chef_run).to render_file(file.name).with_content(line)
            end
          end

          it 'does not have ha rabbit options set' do
            [/^rabbit_hosts=/, /^rabbit_ha_queues=/,
             /^ec2_private_dns_show_ip$/].each do |line|
              expect(chef_run).not_to render_file(file.name).with_content(line)
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
              expect(chef_run).to render_file(file.name).with_content(line)
            end
          end

          it 'does not have non-ha rabbit options set' do
            [/^rabbit_host=127\.0\.0\.1$/, /^rabbit_port=5672$/].each do |line|
              expect(chef_run).not_to render_file(file.name).with_content(line)
            end
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
            expect(chef_run).to render_file(file.name).with_content(line)
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
         /^use_ipv6=false$/].each do |line|
          expect(chef_run).to render_file(file.name).with_content(line)
        end
      end

      it 'has a force_config_drive setting' do
        chef_run.node.set['openstack']['compute']['config']['force_config_drive'] = 'always'
        expect(chef_run).to render_file(file.name).with_content(
          /^force_config_drive=always$/)
      end

      it 'has a os_region_name setting' do
        chef_run.node.set['openstack']['node'] = 'RegionOne'
        expect(chef_run).to render_file(file.name).with_content(
          /^os_region_name=RegionOne$/)
      end

      it 'has a disk_cachemodes setting' do
        chef_run.node.set['openstack']['compute']['config']['disk_cachemodes'] = 'disk:writethrough'
        expect(chef_run).to render_file(file.name).with_content(
          /^disk_cachemodes=disk:writethrough$/)
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
          [/^use_virtio_for_bridges=true$/,
           /^images_type=default$/,
           /^inject_key=true$/,
           /^inject_password=false$/,
           /^inject_partition=-2$/,
           /^live_migration_bandwidth=0$/,
           /^live_migration_flag=VIR_MIGRATE_UNDEFINE_SOURCE, VIR_MIGRATE_PEER2PEER$/,
           /^block_migration_flag=VIR_MIGRATE_UNDEFINE_SOURCE, VIR_MIGRATE_PEER2PEER, VIR_MIGRATE_NON_SHARED_INC$/,
           %r{live_migration_uri=qemu\+tcp://%s/system$}].each do |line|
             expect(chef_run).to render_file(file.name).with_content(line)
           end
        end

        it "the libvirt cpu_mode is none when virt_type is 'qemu'" do
          node.set['openstack']['compute']['libvirt']['virt_type'] = 'qemu'

          expect(chef_run).to render_file(file.name).with_content(
            'cpu_mode=none')
        end

        it 'has a configurable inject_key setting' do
          node.set['openstack']['compute']['libvirt']['libvirt_inject_key'] = false

          expect(chef_run).to render_file(file.name).with_content(
            /^inject_key=false$/)
        end

        it 'has a configurable inject_password setting' do
          node.set['openstack']['compute']['libvirt']['libvirt_inject_password'] = true

          expect(chef_run).to render_file(file.name).with_content(
            /^inject_password=true$/)
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
            expect(chef_run).to render_file(file.name).with_content(line)
          end
        end

        it 'has no datastore_regex line' do
          expect(chef_run).not_to render_file(file.name).with_content('datastore_regex = ')
        end

        it 'has no wsdl_location line' do
          expect(chef_run).not_to render_file(file.name).with_content('wsdl_location = ')
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
          expect(chef_run).to render_file(file.name).with_content('cluster_name = cluster1')
          expect(chef_run).to render_file(file.name).with_content('cluster_name = cluster2')
        end

        it 'has datastore_regex line' do
          expect(chef_run).to render_file(file.name).with_content('datastore_regex = *.')
        end

        it 'has wsdl_location line' do
          expect(chef_run).to render_file(file.name).with_content('wsdl_location = http://127.0.0.1/')
        end
      end

      it 'has scheduler options' do
        [/^scheduler_manager=nova.scheduler.manager.SchedulerManager$/,
         /^compute_scheduler_driver=nova.scheduler.filter_scheduler.FilterScheduler$/,
         /^scheduler_available_filters=nova.scheduler.filters.all_filters$/,
         /^scheduler_default_filters=AvailabilityZoneFilter,RamFilter,ComputeFilter,CoreFilter,SameHostFilter,DifferentHostFilter$/
        ].each do |line|
          expect(chef_run).to render_file(file.name).with_content(line)
        end
      end

      it 'has disk_allocation_ratio when the right filter is set' do
        node.set['openstack']['compute']['scheduler']['default_filters'] = %w(
          AvailabilityZoneFilter
          DiskFilter
          RamFilter
          ComputeFilter
          CoreFilter
          SameHostFilter
          DifferentHostFilter
        )
        expect(chef_run).to render_file(file.name).with_content(
          'disk_allocation_ratio=1.0')
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

        describe 'default rdb settings' do
          it 'sets the libvirt * options correctly' do
            [
              /^images_type=rbd$/,
              /^images_rbd_pool=rbd$/,
              %r{^images_rbd_ceph_conf=/etc/ceph/ceph.conf$},
              /^rbd_user=cinder$/,
              /^rbd_secret_uuid=00000000-0000-0000-0000-000000000000$/
            ].each do |line|
              expect(chef_run).to render_file(file.name).with_content(line)
            end
          end
        end

        describe 'override rbd settings' do
          before do
            node.set['openstack']['compute']['libvirt']['images_type'] = 'rbd'
            node.set['openstack']['compute']['libvirt']['images_rbd_pool'] = 'myrbd'
            node.set['openstack']['compute']['libvirt']['images_rbd_ceph_conf'] = '/etc/myceph/ceph.conf'
          end

          it 'sets the overridden libvirt options correctly' do
            [
              /^images_type=rbd$/,
              /^images_rbd_pool=myrbd$/,
              %r{^images_rbd_ceph_conf=/etc/myceph/ceph.conf$}
            ].each do |line|
              expect(chef_run).to render_file(file.name).with_content(line)
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
            expect(chef_run).to render_file(file.name).with_content(line)
          end
        end

        describe 'override settings' do
          before do
            node.set['openstack']['compute']['libvirt']['images_type'] = 'lvm'
            node.set['openstack']['compute']['libvirt']['volume_group'] = 'instances'
            node.set['openstack']['compute']['libvirt']['sparse_logical_volumes'] = true
          end

          it 'sets the overridden lvm options correctly' do
            [
              /^images_type=lvm$/,
              /^images_volume_group=instances$/,
              /^sparse_logical_volumes=true$/
            ].each do |line|
              expect(chef_run).to render_file(file.name).with_content(line)
            end
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
            %r(^filters_path=/etc/nova/rootwrap.d,/usr/share/nova/rootwrap$),
            %r(^exec_dirs=/sbin,/usr/sbin,/bin,/usr/bin$),
            /^use_syslog=false$/,
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
