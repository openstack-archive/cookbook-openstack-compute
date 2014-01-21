# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-compute::nova-common' do
  before { compute_stubs }
  describe 'ubuntu' do
    before do
      @chef_run = ::ChefSpec::Runner.new(::UBUNTU_OPTS) do |n|
        n.set['openstack']['mq'] = {
          'host' => '127.0.0.1'
        }
        n.set['openstack']['compute']['syslog']['use'] = true
      end
      @chef_run.converge 'openstack-compute::nova-common'
    end

    it "doesn't run epel recipe" do
      expect(@chef_run).to_not include_recipe 'yum::epel'
    end

    it 'runs logging recipe if node attributes say to' do
      expect(@chef_run).to include_recipe 'openstack-common::logging'
    end

    it "doesn't run logging recipe" do
      chef_run = ::ChefSpec::Runner.new ::UBUNTU_OPTS
      chef_run.converge 'openstack-compute::nova-common'
      expect(chef_run).not_to include_recipe 'openstack-common::logging'
    end

    it 'can converge with neutron service type' do
      chef_run = ::ChefSpec::Runner.new ::UBUNTU_OPTS
      node = chef_run.node
      node.set['openstack']['compute']['network']['service_type'] = 'neutron'
      chef_run.converge 'openstack-compute::nova-common'
    end

    it 'installs nova common packages' do
      expect(@chef_run).to upgrade_package 'nova-common'
    end

    it 'installs memcache python packages' do
      expect(@chef_run).to install_package 'python-memcache'
    end

    it 'creates the /etc/nova directory' do
      expect(@chef_run).to create_directory('/etc/nova').with(
        owner: 'nova',
        group: 'nova',
        mode: 0700
      )
    end

    describe 'nova.conf' do
      before do
        @filename = '/etc/nova/nova.conf'
        # need this to evaluate nova.conf.erb template
        @chef_run.node.set['cpu'] = Hash.new
        @chef_run.node.set.cpu.total = '2'
      end

      it 'creates the file' do
        expect(@chef_run).to create_template('/etc/nova/nova.conf').with(
          owner: 'nova',
          group: 'nova',
          mode: 0644
        )
      end

      array = [/^rpc_thread_pool_size=64$/,
               /^rpc_conn_pool_size=30$/,
               /^rpc_response_timeout=60$/,
               /^rabbit_userid=guest$/,
               /^rabbit_password=rabbit-pass$/,
               /^rabbit_virtual_host=\/$/,
               /^rabbit_host=127.0.0.1$/,
               /^rabbit_port=5672$/,
               /^rabbit_use_ssl=false$/,
               /^allow_resize_to_same_host=false$/,
               /^vncserver_listen=127.0.1.1$/,
               /^vncserver_proxyclient_address=127.0.1.1$/,
               /^xvpvncproxy_host=127.0.1.1$/,
               /^novncproxy_host=127.0.1.1$/,
               /^force_dhcp_release=true$/,
               /^rpc_backend=nova.openstack.common.rpc.impl_kombu$/,
               /^libvirt_use_virtio_for_bridges=true$/
      ]
      array.each do |content|
        it "has a #{content.source[1...-1]} line" do
          expect(@chef_run).to render_file(@filename).with_content(content)
        end
      end

      [/^rabbit_hosts=/, /^rabbit_ha_queues=/, /^ec2_private_dns_show_ip$/].each do |content|
        it "does not have a #{content.source[1..-1]} line" do
          expect(@chef_run).not_to render_file(@filename).with_content(content)
        end
      end

      it "the libvirt_cpu_mode is none when virt_type is 'qemu'" do
        @chef_run.node.set['openstack']['compute']['libvirt']['virt_type'] = 'qemu'
        expect(@chef_run).to render_file(@filename).with_content(
          'libvirt_cpu_mode=none')
      end

      it 'has disk_allocation_ratio when the right filter is set' do
        @chef_run.node.set['openstack']['compute']['scheduler']['default_filters'] = %w(
          AvailabilityZoneFilter
          DiskFilter
          RamFilter
          ComputeFilter
          CoreFilter
          SameHostFilter
          DifferentHostFilter
        )
        @chef_run.converge('openstack-compute::nova-common')
        expect(@chef_run).to render_file(@filename).with_content(
          'disk_allocation_ratio=1.0')
      end

      it 'has no auto_assign_floating_ip' do
        @chef_run.node.set['openstack']['compute']['network']['service_type'] = 'neutron'
        expect(@chef_run).not_to render_file(@filename).with_content(
          'auto_assign_floating_ip=false')
      end

      it 'has misc option' do
        @chef_run.node.set['openstack']['compute']['misc_nova'] = ['MISC_OPTION', 'FOO']
        expect(@chef_run).to render_file(@filename).with_content(
          'MISC_OPTION')
      end

      context 'qpid' do
        before do
          @chef_run.node.set['openstack']['mq']['compute']['service_type'] = 'qpid'
          @chef_run.converge 'openstack-compute::nova-common'
        end

        array = [/^qpid_hostname=127.0.0.1$/,
                 /^qpid_port=5672$/,
                 /^qpid_username=$/,
                 /^qpid_password=$/,
                 /^qpid_sasl_mechanisms=$/,
                 /^qpid_reconnect_timeout=0$/,
                 /^qpid_reconnect_limit=0$/,
                 /^qpid_reconnect_interval_min=0$/,
                 /^qpid_reconnect_interval_max=0$/,
                 /^qpid_reconnect_interval=0$/,
                 /^qpid_heartbeat=60$/,
                 /^qpid_protocol=tcp$/,
                 /^qpid_tcp_nodelay=true$/
        ]
        array.each do |content|
          it "has a #{content.source[1...-1]} line" do
            expect(@chef_run).to render_file(@filename).with_content(content)
          end
        end
      end

      describe 'rabbit ha' do
        before do
          @chef_run = ::ChefSpec::Runner.new(::UBUNTU_OPTS) do |n|
            n.set['openstack']['mq']['compute']['rabbit']['ha'] = true
            n.set['cpu'] = {
              'total' => '2'
            }
          end
          @chef_run.converge 'openstack-compute::nova-common'
        end

        [/^rabbit_hosts=1.1.1.1:5672,2.2.2.2:5672$/, /^rabbit_ha_queues=True$/].each do |content|
          it "has a #{content.source[1...-1]} line" do
            expect(@chef_run).to render_file(@filename).with_content(content)
          end
        end

        [/^rabbit_host=127.0.0.1$/, /^rabbit_port=5672$/].each do |content|
          it "does not have a #{content.source[1..-1]} line" do
            expect(@chef_run).not_to render_file(@filename).with_content(content)
          end
        end
      end
    end

    describe 'rootwrap.conf' do
      before { @filename = '/etc/nova/rootwrap.conf' }

      it 'creates the /etc/nova/rootwrap.conf file' do
        expect(@chef_run).to create_template(@filename).with(
          user: 'root',
          group: 'root',
          mode: 0644
        )
      end

      it 'template contents' do
        pending 'TODO: implement'
      end
    end

    describe '/root/openrc' do
      before { @filename = '/root/openrc' }

      it 'creates the /root/openrc file' do
        expect(@chef_run).to create_template(@filename).with(
          user: 'root',
          group: 'root',
          mode: 0600
        )
      end

      [/^export OS_USERNAME=admin/, /^export OS_TENANT_NAME=admin$/, /^export OS_PASSWORD=admin$/].each do |content|
        it "has a #{content.source[1...-1]} line" do
          expect(@chef_run).to render_file(@filename).with_content(content)
        end
      end

      it 'has misc option' do
        @chef_run.node.set['openstack']['compute']['misc_openrc'] = ['MISC_OPTION', 'FOO']
        expect(@chef_run).to render_file(@filename).with_content(
          'MISC_OPTION')
      end

      it 'rest of template contents' do
        pending 'TODO: implement'
      end
    end

    it 'enables nova login' do
      expect(@chef_run).to run_execute('usermod -s /bin/sh nova')
    end
  end
end
