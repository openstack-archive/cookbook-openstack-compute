# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-compute::nova-common' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) do
      node.set['openstack']['mq'] = {
        'host' => '127.0.0.1',
      }
      node.set['openstack']['mq']['compute']['rabbit']['ha'] = true

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
        mode: 0o750
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
          mode: 0o640
        )
      end

      it 'has default *_path options set' do
        [%r{^log_dir = /var/log/nova$},
         %r{^state_path = /var/lib/nova$},
         %r{^instances_path = /var/lib/nova/instances$},
         %r{^lock_path = /var/lib/nova/lock$}].each do |line|
          expect(chef_run).to render_file(file.name).with_content(line)
        end
      end

      it 'has compute driver attributes defaults set' do
        [/^compute_driver = libvirt.LibvirtDriver$/].each do |line|
          expect(chef_run).to render_file(file.name).with_content(line)
        end
      end

      it 'has default misc config attributes defaults not set' do
        [/^osapi_compute_link_prefix = /,
         /^osapi_glance_link_prefix = /].each do |line|
          expect(chef_run).not_to render_config_file(file.name).with_section_content('DEFAULT', line)
        end
      end

      it 'has default transport_url/AMQP options set' do
        [%r{^transport_url = rabbit://guest:mypass@127.0.0.1:5672$}].each do |line|
          expect(chef_run).to render_file(file.name).with_content(line)
        end
      end

      it 'has default compute ip and port options set' do
        [/^osapi_compute_listen = 127.0.0.1$/,
         /^osapi_compute_listen_port = 8774$/].each do |line|
          expect(chef_run).to render_file(file.name).with_content(line)
        end
      end

      it 'has default metadata ip and port options set' do
        [/^metadata_listen = 127.0.0.1$/,
         /^metadata_listen_port = 8775$/].each do |line|
          expect(chef_run).to render_file(file.name).with_content(line)
        end
      end

      it 'confirms default min value for workers' do
        [/^osapi_compute_workers = /,
         /^metadata_workers = /,
         /^workers = /].each do |line|
          expect(chef_run).to_not render_file(file.name).with_content(line)
        end
      end

      context 'keystone_authtoken' do
        it 'has correct auth_token settings' do
          [
            'auth_url = http://127.0.0.1:5000/v3',
            'password = nova-pass',
            'username = nova',
            'project_name = service',
            'user_domain_name = Default',
            'project_domain_name = Default',
          ].each do |line|
            expect(chef_run).to render_config_file(file.name)\
              .with_section_content('keystone_authtoken', /^#{Regexp.quote(line)}$/)
          end
        end
      end

      context 'placement' do
        it 'has correct authentication settings' do
          [
            'auth_type = password',
            'os_region_name = RegionOne',
            'password = placement-pass',
            'username = placement',
            'project_name = service',
            'user_domain_name = Default',
            'project_domain_name = Default',
          ].each do |line|
            expect(chef_run).to render_config_file(file.name)\
              .with_section_content('placement', /^#{Regexp.quote(line)}$/)
          end
        end
      end

      it 'uses default values for attributes' do
        [
          %r{^api_servers = http://127.0.0.1:9292$},

        ].each do |line|
          expect(chef_run).to render_config_file(file.name)\
            .with_section_content('glance', line)
        end
      end

      it do
        [
          /^username = neutron$/,
          /^project_name = service$/,
          /^user_domain_name = Default/,
          /^project_domain_name = Default/,
          %r{^url = http://127.0.0.1:9696$},
        ].each do |line|
          expect(chef_run).to render_config_file(file.name)\
            .with_section_content('neutron', line)
        end
      end

      it 'sets scheme for neutron' do
        node.set['openstack']['endpoints']['internal']['network']['scheme'] = 'https'
        expect(chef_run).to render_config_file(file.name)\
          .with_section_content('neutron', %r{^url = https://127.0.0.1:9696$})
      end

      context 'rabbit mq backend' do
        describe 'ha rabbit disabled' do
          before do
            # README(galstrom21): There is a order of operations issue here
            #   if you use node.set, these tests will fail.
            node.override['openstack']['mq']['compute']['rabbit']['ha'] = false
          end

          it 'does not have ha rabbit options set' do
            [/^rabbit_hosts = /, /^rabbit_ha_queues = /].each do |line|
              expect(chef_run).not_to render_config_file(file.name).with_section_content('oslo_messaging_rabbit', line)
            end
          end
        end
      end

      it 'has default vncserver_* options set' do
        node.set['openstack']['endpoints']['compute-vnc-bind']['bind_interface'] = 'lo'

        [/^vncserver_listen = 127.0.0.1$/,
         /^vncserver_proxyclient_address = 127.0.0.1$/].each do |line|
          expect(chef_run).to render_file(file.name).with_content(line)
        end
      end

      it 'has override vncserver_* options set' do
        node.set['openstack']['bind_service']['all']['compute-vnc']['host'] = '1.1.1.1'
        node.set['openstack']['bind_service']['all']['compute-vnc-proxy']['host'] = '2.2.2.2'

        [/^vncserver_listen = 1.1.1.1$/,
         /^vncserver_proxyclient_address = 2.2.2.2$/].each do |line|
          expect(chef_run).to render_file(file.name).with_content(line)
        end
      end

      it 'has default *vncproxy_* options set' do
        [/^xvpvncproxy_host = 127.0.0.1$/,
         /^xvpvncproxy_port = 6081$/,
         /^novncproxy_host = 127.0.0.1$/,
         /^novncproxy_port = 6080$/].each do |line|
          expect(chef_run).to render_file(file.name).with_content(line)
        end
      end

      it 'has a os_region_name setting' do
        chef_run.node.set['openstack']['node'] = 'RegionOne'
        expect(chef_run).to render_config_file(file.name)\
          .with_section_content('cinder', /^os_region_name = RegionOne$/)
      end

      it 'has no auto_assign_floating_ip' do
        expect(chef_run).not_to render_file(file.name).with_content(
          'auto_assign_floating_ip=false'
        )
      end

      context 'lvm backend' do
        before do
          node.set['openstack']['compute']['conf']['libvirt']['images_type'] = 'lvm'
          node.set['openstack']['compute']['conf']['libvirt']['images_volume_group'] = 'instances'
        end

        it 'sets the lvm options correctly' do
          [
            /^images_type = lvm$/,
            /^images_volume_group = instances$/,
            /^sparse_logical_volumes = false$/,
          ].each do |line|
            expect(chef_run).to render_config_file(file.name)\
              .with_section_content('libvirt', line)
          end
        end

        describe 'override settings' do
          before do
            node.set['openstack']['compute']['conf']['libvirt']['images_type'] = 'lvm'
            node.set['openstack']['compute']['conf']['libvirt']['images_volume_group'] = 'instances'
            node.set['openstack']['compute']['conf']['libvirt']['sparse_logical_volumes'] = true
            # node.set['openstack']['compute']['libvirt']['cpu_mode'] = 'none'
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
            # /^enabled = False$/,
            %r{base_url = ws://127.0.0.1:6083$},
            # /^port_range = 10000:20000$/,
            /^proxyclient_address = 127.0.0.1$/,
          ].each do |line|
            expect(chef_run).to render_config_file(file.name)\
              .with_section_content('serial_console', line)
          end
        end

        it 'sets overide serial console options set' do
          node.set['openstack']['endpoints']['compute-serial-console-bind']['bind_interface'] = 'lo'
          node.set['openstack']['endpoints']['public']['compute-serial-proxy']['scheme'] = 'wss'
          node.set['openstack']['endpoints']['public']['compute-serial-proxy']['host'] = '1.1.1.1'
          node.set['openstack']['endpoints']['public']['compute-serial-proxy']['port'] = '6082'
          # node.set['openstack']['compute']['serial_console']['enable'] = 'True'
          # node.set['openstack']['compute']['serial_console']['port_range'] = '11000:15000'

          [
            # /^enabled = True$/,
            %r{base_url = wss://1.1.1.1:6082$},
            # /^port_range = 11000:15000$/,
            /^proxyclient_address = 127.0.0.1$/,
          ].each do |line|
            expect(chef_run).to render_config_file(file.name)\
              .with_section_content('serial_console', line)
          end
        end
      end

      it do
        node.set['openstack']['db']['compute_api']['username'] = 'nova_api'
        expect(chef_run).to render_config_file(file.name)
          .with_section_content(
            'api_database',
            %(connection = mysql+pymysql://nova_api:nova_api_db_pass@127.0.0.1:3306/nova_api?charset=utf8)
          )
      end

      context 'set enabled_slave attribute' do
        it 'sets overide database enabled_slave attribute as true' do
          node.set['openstack']['endpoints']['db']['enabled_slave'] = true
          node.set['openstack']['endpoints']['db']['slave_host'] = '10.10.1.1'
          node.set['openstack']['endpoints']['db']['slave_port'] = '3326'
          node.set['openstack']['db']['compute']['username'] = 'nova'

          expect(chef_run).to render_config_file(file.name)\
            .with_section_content('database', %(slave_connection = mysql+pymysql://nova:nova_db_pass@10.10.1.1:3326/nova?charset=utf8))
        end

        it 'sets overide database enabled_slave attribute as false' do
          node.set['openstack']['endpoints']['db']['enabled_slave'] = false
          node.set['openstack']['endpoints']['db']['slave_host'] = '10.10.1.1'
          node.set['openstack']['endpoints']['db']['slave_port'] = '3326'
          node.set['openstack']['db']['compute']['username'] = 'nova'

          expect(chef_run).to_not render_config_file(file.name)\
            .with_section_content('database', %(slave_connection = mysql+pymysql://nova:nova_db_pass@10.10.1.1:3326/nova?charset=utf8))
        end
      end
    end

    describe 'rootwrap.conf' do
      let(:file) { chef_run.template('/etc/nova/rootwrap.conf') }

      it 'creates the /etc/nova/rootwrap.conf file' do
        expect(chef_run).to create_template(file.name).with(
          user: 'root',
          group: 'root',
          mode: 0o644
        )
      end

      context 'template contents' do
        it 'shows the custom banner' do
          node.set['openstack']['compute']['custom_template_banner'] = 'banner'

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

    it 'enables nova login' do
      expect(chef_run).to run_execute('usermod -s /bin/sh nova')
    end
    it do
      expect(chef_run).to run_ruby_block("delete all attributes in node['openstack']['compute']['conf_secrets']")
    end
  end
end
