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

    it "doesn't run epel recipe" do
      expect(chef_run).to_not include_recipe 'yum-epel'
    end

    it 'installs nova common packages' do
      expect(chef_run).to upgrade_package 'nova-common'
    end

    it 'installs memcache python packages' do
      expect(chef_run).to install_package 'python-memcache'
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

    context 'with logging enabled' do
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
          mode: 0644
        )
      end

      it 'has default *_path options set' do
        [%r{^log_dir=/var/log/nova$},
         %r{^state_path=/var/lib/nova$},
         /^instances_path=\$state_path\/instances$/,
         /^lock_path=\$state_path\/lock$/].each do |line|
          expect(chef_run).to render_file(file.name).with_content(line)
        end
      end

      it 'has default rpc_* options set' do
        [/^rpc_thread_pool_size=64$/, /^rpc_conn_pool_size=30$/,
         /^rpc_backend=nova.openstack.common.rpc.impl_kombu$/,
         /^rpc_response_timeout=60$/].each do |line|
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
            /^qpid_tcp_nodelay=true$/
          ].each do |line|
            expect(chef_run).to render_file(file.name).with_content(line)
          end
        end
      end

      it 'has default vncserver_* options set' do
        [/^vncserver_listen=127.0.1.1$/,
         /^vncserver_proxyclient_address=127.0.1.1$/].each do |line|
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
         %r{^injected_network_template=\$pybasedir/nova/virt/interfaces.template$}].each do |line|
          expect(chef_run).to render_file(file.name).with_content(line)
        end
      end

      it 'has a force_config_drive setting' do
        chef_run.node.set['openstack']['compute']['config']['force_config_drive'] = 'always'
        expect(chef_run).to render_file(file.name).with_content(
          /^force_config_drive=always$/)
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
             'notify_on_state_change=vm_and_task_state'
            ].each do |line|
              expect(chef_run).to render_file(file.name).with_content(line)
            end
          end
        end
      end

      context 'libvirt configuration' do
        it 'has default libvirt_* options set' do
          [/^libvirt_use_virtio_for_bridges=true$/,
           /^libvirt_images_type=default$/,
           /^libvirt_inject_key=true$/].each do |line|
             expect(chef_run).to render_file(file.name).with_content(line)
           end
        end

        it "the libvirt_cpu_mode is none when virt_type is 'qemu'" do
          node.set['openstack']['compute']['libvirt']['virt_type'] = 'qemu'

          expect(chef_run).to render_file(file.name).with_content(
            'libvirt_cpu_mode=none')
        end

        it 'has a configurable libvirt_inject_key setting' do
          node.set['openstack']['compute']['libvirt']['libvirt_inject_key'] = false

          expect(chef_run).to render_file(file.name).with_content(
            /^libvirt_inject_key=false$/)
        end
      end

      context 'vmware' do
        before do
          # README(galstrom21): There is a order of operations issue here
          #   if you use node.set, these tests will fail.
          node.override['openstack']['compute']['driver'] = 'vmwareapi.VMwareVCDriver'
        end

        it 'has default vmware config options set' do
          [
            /^host_ip = $/,
            /^host_username = $/,
            /^host_password = $/,
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
          it 'sets the libvirt_* options correctly' do
            [
              /^libvirt_images_type=rbd$/,
              /^libvirt_images_rbd_pool=rbd$/,
              %r{^libvirt_images_rbd_ceph_conf=/etc/ceph/ceph.conf$},
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

          it 'sets the overridden libvirt_* options correctly' do
            [
              /^libvirt_images_type=rbd$/,
              /^libvirt_images_rbd_pool=myrbd$/,
              %r{^libvirt_images_rbd_ceph_conf=/etc/myceph/ceph.conf$}
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

        [
          /^libvirt_images_type=lvm$/,
          /^libvirt_images_volume_group=instances$/,
          /^libvirt_sparse_logical_volumes=false$/
        ].each do |content|
          it "has a #{content.source[1...-1]} line" do
            expect(chef_run).to render_file(file.name).with_content(content)
          end
        end

        describe 'override settings' do
          before do
            node.set['openstack']['compute']['libvirt']['images_type'] = 'lvm'
            node.set['openstack']['compute']['libvirt']['volume_group'] = 'instances'
            node.set['openstack']['compute']['libvirt']['sparse_logical_volumes'] = true
          end

          [
            /^libvirt_images_type=lvm$/,
            /^libvirt_images_volume_group=instances$/,
            /^libvirt_sparse_logical_volumes=true$/
          ].each do |content|
            it "has a #{content.source[1...-1]} line" do
              expect(chef_run).to render_file(file.name).with_content(content)
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
            /^use_syslog=False$/,
            /^syslog_log_facility=syslog$/,
            /^syslog_log_level=ERROR$/
          ].each do |line|
            expect(chef_run).to render_file(file.name).with_content(line)
          end
        end
      end
    end

    describe '/root/openrc' do
      let(:file) { chef_run.template('/root/openrc') }

      it 'creates the /root/openrc file' do
        expect(chef_run).to create_template(file.name).with(
          user: 'root',
          group: 'root',
          mode: 0600
        )
      end

      it 'contains auth environment variables' do
        [
          /^export OS_USERNAME=admin/,
          /^export OS_TENANT_NAME=admin$/,
          /^export OS_PASSWORD=admin$/
        ].each do |line|
          expect(chef_run).to render_file(file.name).with_content(line)
        end
      end

      it 'templates misc_openrc array correctly' do
        node.set['openstack']['compute']['misc_openrc'] = ['MISC_OPTION', 'FOO']
        expect(chef_run).to render_file(file.name).with_content(
          'MISC_OPTION')
      end

      context 'rest of template contents' do
        it 'contains additional auth environment variables' do
          endpoint = double(to_s: 'endpoint', host: 'endpoint', port: 'port')
          Chef::Recipe.any_instance.should_receive(:endpoint)
            .at_least(1).times.and_return(endpoint)
          node.set['openstack']['compute']['region'] = 'os_region_name'
          [
            /^export OS_AUTH_URL=endpoint$/,
            /^export OS_AUTH_STRATEGY=keystone$/,
            /^export OS_REGION_NAME=os_region_name$/
          ].each do |line|
            expect(chef_run).to render_file(file.name).with_content(line)
          end
        end
        it 'contains legacy nova envs' do
          node.set['openstack']['compute']['region'] = 'os_region_name'
          [
            /^export NOVA_USERNAME=\${OS_USERNAME}$/,
            /^export NOVA_PROJECT_ID=\${OS_TENANT_NAME}$/,
            /^export NOVA_PASSWORD=\${OS_PASSWORD}$/,
            /^export NOVA_API_KEY=\${OS_PASSWORD}$/,
            /^export NOVA_URL=\${OS_AUTH_URL}$/,
            /^export NOVA_VERSION=$/,
            /^export NOVA_REGION_NAME=os_region_name$/
          ].each do |line|
            expect(chef_run).to render_file(file.name).with_content(line)
          end
        end

        it 'contains euca2ools env variables' do
          node.set['credentials']['EC2']['admin']['access'] = 'ec2_admin_access'
          node.set['credentials']['EC2']['admin']['secret'] = 'ec2_admin_secret'
          endpoint = double(to_s: 'endpoint', host: 'endpoint', port: 'port')
          Chef::Recipe.any_instance.should_receive(:endpoint)
            .at_least(1).times.and_return(endpoint)

          [
            /^export EC2_ACCESS_KEY=ec2_admin_access$/,
            /^export EC2_SECRET_KEY=ec2_admin_secret$/,
            /^export EC2_URL=endpoint$/
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
