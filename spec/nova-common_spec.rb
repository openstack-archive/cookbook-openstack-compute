require_relative 'spec_helper'

describe 'openstack-compute::nova-common' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    cached(:chef_run) do
      node.override['openstack']['mq'] = { 'host' => '127.0.0.1' }
      node.override['openstack']['mq']['compute']['rabbit']['ha'] = true
      runner.converge(described_recipe)
    end

    include_context 'compute_stubs'
    include_examples 'expect_creates_nova_state_dir'
    include_examples 'expect_creates_nova_lock_dir'

    it do
      expect(chef_run).to upgrade_package 'python3-mysqldb'
    end

    it do
      expect(chef_run).to upgrade_package %w(nova-common python3-nova)
    end

    it do
      expect(chef_run).to upgrade_package 'python3-memcache'
    end

    it 'creates the /etc/nova directory' do
      expect(chef_run).to create_directory('/etc/nova').with(
        owner: 'nova',
        group: 'nova',
        mode: '750'
      )
    end

    context 'with logging enabled' do
      cached(:chef_run) do
        node.override['openstack']['compute']['syslog']['use'] = true
        runner.converge(described_recipe)
      end

      it 'runs logging recipe if node attributes say to' do
        expect(chef_run).to include_recipe 'openstack-common::logging'
      end
    end

    context 'with logging disabled' do
      cached(:chef_run) do
        node.override['openstack']['compute']['syslog']['use'] = false
        runner.converge(described_recipe)
      end

      it "doesn't run logging recipe" do
        expect(chef_run).not_to include_recipe 'openstack-common::logging'
      end
    end

    describe 'nova.conf' do
      let(:file) { chef_run.template('/etc/nova/nova.conf') }

      it do
        expect(chef_run).to create_template(file.name).with(
          source: 'openstack-service.conf.erb',
          cookbook: 'openstack-common',
          owner: 'nova',
          group: 'nova',
          mode: '640',
          sensitive: true
        )
      end

      it '[DEFAULT]' do
        [
          %r{^log_dir = /var/log/nova$},
          %r{^state_path = /var/lib/nova$},
          /^compute_driver = libvirt.LibvirtDriver$/,
          %r{^instances_path = /var/lib/nova/instances$},
          /^enabled_apis = osapi_compute,metadata$/,
          /^iscsi_helper = tgtadm$/,
          /^metadata_listen = 127.0.0.1$/,
          /^metadata_listen_port = 8775$/,
          %r{^transport_url = rabbit://guest:mypass@127.0.0.1:5672$},
        ].each do |line|
          expect(chef_run).to render_config_file(file.name).with_section_content('DEFAULT', line)
        end
      end

      it '[oslo_concurrency]' do
        [
          %r{^lock_path = /var/lib/nova/lock$},
        ].each do |line|
          expect(chef_run).to render_config_file(file.name).with_section_content('oslo_concurrency', line)
        end
      end

      it 'has default misc config attributes defaults not set' do
        [
          /^osapi_compute_link_prefix = /,
          /^osapi_glance_link_prefix = /,
        ].each do |line|
          expect(chef_run).not_to render_config_file(file.name).with_section_content('DEFAULT', line)
        end
      end

      it 'confirms default min value for workers' do
        [
          /^osapi_compute_workers = /,
          /^metadata_workers = /,
          /^workers = /,
        ].each do |line|
          expect(chef_run).to_not render_file(file.name).with_content(line)
        end
      end

      it '[keystone_authtoken]' do
        [
          /^auth_type = v3password$/,
          /^region_name = RegionOne$/,
          /^username = nova$/,
          /^user_domain_name = Default$/,
          /^project_domain_name = Default$/,
          /^project_name = service$/,
          /^auth_version = v3$/,
          /^service_token_roles_required = true$/,
          %r{^auth_url = http://127.0.0.1:5000/v3$},
          %r{^www_authenticate_uri = http://127.0.0.1:5000/v3$},
          /^password = nova-pass$/,
        ].each do |line|
          expect(chef_run).to render_config_file(file.name).with_section_content('keystone_authtoken', line)
        end
      end

      it '[libvirt]' do
        [
          /^virt_type = kvm$/,
          /^images_type = default$/,
        ].each do |line|
          expect(chef_run).to render_config_file(file.name).with_section_content('libvirt', line)
        end
      end

      it '[neutron]' do
        [
          /^auth_type = v3password$/,
          /^region_name = RegionOne$/,
          /^username = neutron$/,
          /^user_domain_name = Default$/,
          /^service_metadata_proxy = true$/,
          /^project_name = service$/,
          /^project_domain_name = Default$/,
          %r{^auth_url = http://127.0.0.1:5000/v3$},
          /^password = neutron-pass$/,
          /^metadata_proxy_shared_secret = metadata-secret$/,
        ].each do |line|
          expect(chef_run).to render_config_file(file.name).with_section_content('neutron', line)
        end
      end

      it '[placement]' do
        [
          /^auth_type = password$/,
          /^region_name = RegionOne$/,
          /^username = placement$/,
          /^user_domain_name = Default$/,
          /^project_domain_name = Default$/,
          /^project_name = service$/,
          %r{^auth_url = http://127.0.0.1:5000/v3$},
          /^password = placement-pass$/,
        ].each do |line|
          expect(chef_run).to render_config_file(file.name).with_section_content('placement', line)
        end
      end

      it '[scheduler]' do
        [
          /^discover_hosts_in_cells_interval = 300$/,
        ].each do |line|
          expect(chef_run).to render_config_file(file.name).with_section_content('scheduler', line)
        end
      end

      it '[glance]' do
        [
          %r{^api_servers = http://127.0.0.1:9292$},
        ].each do |line|
          expect(chef_run).to render_config_file(file.name).with_section_content('glance', line)
        end
      end

      context 'rabbit mq backend' do
        describe 'ha rabbit disabled' do
          cached(:chef_run) do
            # README(galstrom21): There is a order of operations issue here
            #   if you use node.override, these tests will fail.
            node.override['openstack']['mq']['compute']['rabbit']['ha'] = false
            runner.converge(described_recipe)
          end

          it 'does not have ha rabbit options set' do
            [
              /^rabbit_hosts = /,
              /^rabbit_ha_queues = /,
            ].each do |line|
              expect(chef_run).not_to render_config_file(file.name)
                .with_section_content('oslo_messaging_rabbit', line)
            end
          end
        end
      end

      context 'has default server_* options set' do
        cached(:chef_run) do
          node.override['openstack']['endpoints']['compute-vnc-bind']['bind_interface'] = 'lo'
          runner.converge(described_recipe)
        end
        it do
          [
            /^server_listen = 127.0.0.1$/,
            /^server_proxyclient_address = 127.0.0.1$/,
          ].each do |line|
            expect(chef_run).to render_config_file(file.name).with_section_content('vnc', line)
          end
        end
      end

      context 'has override server_* options set' do
        cached(:chef_run) do
          node.override['openstack']['bind_service']['all']['compute-vnc']['host'] = '1.1.1.1'
          node.override['openstack']['bind_service']['all']['compute-vnc-proxy']['host'] = '2.2.2.2'
          runner.converge(described_recipe)
        end
        it do
          [
            /^server_listen = 1.1.1.1$/,
            /^server_proxyclient_address = 2.2.2.2$/,
          ].each do |line|
            expect(chef_run).to render_config_file(file.name).with_section_content('vnc', line)
          end
        end
      end

      it '[vnc]' do
        [
          %r{^novncproxy_base_url = http://127.0.0.1:6080/vnc_auto.html$},
          %r{^xvpvncproxy_base_url = http://127.0.0.1:6081/console$},
          /^xvpvncproxy_host = 127.0.0.1$/,
          /^xvpvncproxy_port = 6081$/,
          /^novncproxy_host = 127.0.0.1$/,
          /^novncproxy_port = 6080$/,
          /^server_listen = 127.0.0.1$/,
          /^server_proxyclient_address = 127.0.0.1$/,
        ].each do |line|
          expect(chef_run).to render_config_file(file.name).with_section_content('vnc', line)
        end
      end

      context 'has a os_region_name setting' do
        cached(:chef_run) do
          node.override['openstack']['node'] = 'RegionOne'
          runner.converge(described_recipe)
        end
        it do
          expect(chef_run).to render_config_file(file.name)
            .with_section_content('cinder', /^os_region_name = RegionOne$/)
        end
      end

      it 'has no auto_assign_floating_ip' do
        expect(chef_run).not_to render_file(file.name).with_content(
          'auto_assign_floating_ip=false'
        )
      end

      context 'lvm backend' do
        cached(:chef_run) do
          node.override['openstack']['compute']['conf']['libvirt']['images_type'] = 'lvm'
          node.override['openstack']['compute']['conf']['libvirt']['images_volume_group'] = 'instances'
          runner.converge(described_recipe)
        end

        it 'sets the lvm options correctly' do
          [
            /^images_type = lvm$/,
            /^images_volume_group = instances$/,
            /^sparse_logical_volumes = false$/,
          ].each do |line|
            expect(chef_run).to render_config_file(file.name).with_section_content('libvirt', line)
          end
        end

        context 'override settings' do
          cached(:chef_run) do
            node.override['openstack']['compute']['conf']['libvirt']['images_type'] = 'lvm'
            node.override['openstack']['compute']['conf']['libvirt']['images_volume_group'] = 'instances'
            node.override['openstack']['compute']['conf']['libvirt']['sparse_logical_volumes'] = true
            # node.override['openstack']['compute']['libvirt']['cpu_mode'] = 'none'
            runner.converge(described_recipe)
          end

          it 'sets the overridden lvm options correctly' do
            [
              /^images_type = lvm$/,
              /^images_volume_group = instances$/,
              /^sparse_logical_volumes = true$/,
              # /^cpu_mode = none$/
            ].each do |line|
              expect(chef_run).to render_config_file(file.name)\
                .with_section_content('libvirt', line)
            end
          end
        end
      end

      context 'serial console' do
        it 'sets default serial console options set' do
          [
            %r{base_url = ws://127.0.0.1:6083$},
            /^proxyclient_address = 127.0.0.1$/,
          ].each do |line|
            expect(chef_run).to render_config_file(file.name).with_section_content('serial_console', line)
          end
        end

        context 'sets overide serial console options set' do
          cached(:chef_run) do
            node.override['openstack']['endpoints']['compute-serial-console-bind']['bind_interface'] = 'lo'
            node.override['openstack']['endpoints']['public']['compute-serial-proxy']['scheme'] = 'wss'
            node.override['openstack']['endpoints']['public']['compute-serial-proxy']['host'] = '1.1.1.1'
            node.override['openstack']['endpoints']['public']['compute-serial-proxy']['port'] = '6082'
            runner.converge(described_recipe)
          end
          it do
            [
              %r{base_url = wss://1.1.1.1:6082$},
              /^proxyclient_address = 127.0.0.1$/,
            ].each do |line|
              expect(chef_run).to render_config_file(file.name).with_section_content('serial_console', line)
            end
          end
        end
      end

      context 'override compute_api username' do
        cached(:chef_run) do
          node.override['openstack']['db']['compute_api']['username'] = 'nova_api'
          runner.converge(described_recipe)
        end
        it do
          expect(chef_run).to render_config_file(file.name)
            .with_section_content(
              'api_database',
              %(connection = mysql+pymysql://nova_api:nova_api_db_pass@127.0.0.1:3306/nova_api?charset=utf8)
            )
        end
      end

      context 'set enabled_slave attribute' do
        cached(:chef_run) do
          node.override['openstack']['endpoints']['db']['enabled_slave'] = true
          node.override['openstack']['endpoints']['db']['slave_host'] = '10.10.1.1'
          node.override['openstack']['endpoints']['db']['slave_port'] = '3326'
          node.override['openstack']['db']['compute']['username'] = 'nova'
          runner.converge(described_recipe)
        end
        it 'sets overide database enabled_slave attribute as true' do
          expect(chef_run).to render_config_file(file.name)\
            .with_section_content(
              'database',
              %(slave_connection = mysql+pymysql://nova:nova_db_pass@10.10.1.1:3326/nova?charset=utf8)
            )
        end

        context 'sets overide database enabled_slave attribute as false' do
          cached(:chef_run) do
            node.override['openstack']['endpoints']['db']['enabled_slave'] = false
            node.override['openstack']['endpoints']['db']['slave_host'] = '10.10.1.1'
            node.override['openstack']['endpoints']['db']['slave_port'] = '3326'
            node.override['openstack']['db']['compute']['username'] = 'nova'
            runner.converge(described_recipe)
          end
          it do
            expect(chef_run).to_not render_config_file(file.name)\
              .with_section_content(
                'database',
                %(slave_connection = mysql+pymysql://nova:nova_db_pass@10.10.1.1:3326/nova?charset=utf8)
              )
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
          mode: '644'
        )
      end

      context 'template contents' do
        cached(:chef_run) do
          node.override['openstack']['compute']['custom_template_banner'] = 'banner'
          runner.converge(described_recipe)
        end
        it 'shows the custom banner' do
          expect(chef_run).to render_file(file.name).with_content(/^banner$/)
        end

        it 'sets the default attributes' do
          [
            %r{^filters_path = /etc/nova/rootwrap.d,/usr/share/nova/rootwrap$},
            %r{^exec_dirs = /sbin,/usr/sbin,/bin,/usr/bin$},
            /^use_syslog = False$/,
            /^syslog_log_facility = syslog$/,
            /^syslog_log_level = ERROR$/,
          ].each do |line|
            expect(chef_run).to render_file(file.name).with_content(line)
          end
        end
      end
    end

    it do
      expect(chef_run).to modify_user('nova').with(shell: '/bin/sh')
    end

    it 'cleans up conf_secrets' do
      expect(chef_run).to run_ruby_block("delete all attributes in node['openstack']['compute']['conf_secrets']")
    end
  end
end
