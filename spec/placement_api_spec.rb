require_relative 'spec_helper'

describe 'openstack-compute::placement_api' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    cached(:chef_run) { runner.converge(described_recipe) }

    include_context 'compute_stubs'

    include_examples 'expect_runs_nova_apache_recipe'

    it do
      expect(chef_run).to upgrade_package %w(python3-nova libapache2-mod-wsgi-py3 nova-placement-api)
    end

    it 'executes placement-api: nova-manage api_db sync' do
      expect(chef_run).to run_execute('placement-api: nova-manage api_db sync').with(
        timeout: 3600,
        user: 'nova',
        group: 'nova',
        command: 'nova-manage api_db sync'
      )
    end

    it do
      expect(chef_run).to disable_service 'nova-placement-api'
      expect(chef_run).to stop_service 'nova-placement-api'
    end

    it do
      expect(chef_run).to disable_apache2_site('nova-placement-api')
    end

    it do
      expect(chef_run).to install_apache2_install('openstack').with(listen: %w(127.0.0.1:8778))
    end

    it do
      expect(chef_run).to enable_apache2_module('wsgi')
    end

    it do
      expect(chef_run).to_not enable_apache2_module('ssl')
    end

    it do
      expect(chef_run).to create_template('/etc/apache2/sites-available/nova-placement.conf').with(
        source: 'wsgi-template.conf.erb',
        variables: {
          ca_certs_path: '',
          cert_file: '',
          cert_required: false,
          chain_file: '',
          ciphers: '',
          daemon_process: 'placement-api',
          group: 'nova',
          key_file: '',
          log_dir: '/var/log/apache2',
          processes: 2,
          protocol: '',
          run_dir: '/var/lock',
          server_entry: '/usr/bin/nova-placement-api',
          server_host: '127.0.0.1',
          server_port: '8778',
          threads: 1,
          user: 'nova',
          use_ssl: false,
        }
      )
    end
    [
      /<VirtualHost 127.0.0.1:8778>$/,
      /WSGIDaemonProcess placement-api processes=2 threads=1 user=nova group=nova display-name=%{GROUP}$/,
      /WSGIProcessGroup placement-api$/,
      %r{WSGIScriptAlias / /usr/bin/nova-placement-api$},
      /WSGIApplicationGroup %{GLOBAL}$/,
      %r{ErrorLog /var/log/apache2/placement-api_error.log$},
      %r{CustomLog /var/log/apache2/placement-api_access.log combined$},
      %r{WSGISocketPrefix /var/lock$},
    ].each do |line|
      it do
        expect(chef_run).to render_file('/etc/apache2/sites-available/nova-placement.conf').with_content(line)
      end
    end

    [
      /SSLEngine On$/,
      /SSLCertificateFile/,
      /SSLCertificateKeyFile/,
      /SSLCACertificatePath/,
      /SSLCertificateChainFile/,
      /SSLProtocol/,
      /SSLCipherSuite/,
      /SSLVerifyClient require/,
    ].each do |line|
      it do
        expect(chef_run).to_not render_file('/etc/apache2/sites-available/nova-placement.conf').with_content(line)
      end
    end

    context 'Enable SSL' do
      cached(:chef_run) do
        node.override['openstack']['compute']['placement']['ssl']['enabled'] = true
        node.override['openstack']['compute']['placement']['ssl']['certfile'] = 'ssl.cert'
        node.override['openstack']['compute']['placement']['ssl']['keyfile'] = 'ssl.key'
        node.override['openstack']['compute']['placement']['ssl']['ca_certs_path'] = 'ca_certs_path'
        node.override['openstack']['compute']['placement']['ssl']['protocol'] = 'ssl_protocol_value'
        runner.converge(described_recipe)
      end

      it do
        expect(chef_run).to enable_apache2_module('ssl')
      end

      [
        /SSLEngine On$/,
        /SSLCertificateFile ssl.cert$/,
        /SSLCertificateKeyFile ssl.key$/,
        /SSLCACertificatePath ca_certs_path$/,
        /SSLProtocol ssl_protocol_value$/,
      ].each do |line|
        it do
          expect(chef_run).to render_file('/etc/apache2/sites-available/nova-placement.conf').with_content(line)
        end
      end
      [
        /SSLCipherSuite/,
        /SSLCertificateChainFile/,
        /SSLVerifyClient require/,
      ].each do |line|
        it do
          expect(chef_run).to_not render_file('/etc/apache2/sites-available/nova-placement.conf').with_content(line)
        end
      end
      context 'Enable chainfile, ciphers & cert_required' do
        cached(:chef_run) do
          node.override['openstack']['compute']['placement']['ssl']['enabled'] = true
          node.override['openstack']['compute']['placement']['ssl']['ciphers'] = 'ssl_ciphers_value'
          node.override['openstack']['compute']['placement']['ssl']['chainfile'] = 'chainfile'
          node.override['openstack']['compute']['placement']['ssl']['cert_required'] = true
          runner.converge(described_recipe)
        end
        [
          /SSLCipherSuite ssl_ciphers_value$/,
          /SSLCertificateChainFile chainfile$/,
          /SSLVerifyClient require/,
        ].each do |line|
          it do
            expect(chef_run).to render_file('/etc/apache2/sites-available/nova-placement.conf').with_content(line)
          end
        end
      end
    end

    it do
      expect(chef_run.template('/etc/apache2/sites-available/nova-placement.conf')).to \
        notify('service[apache2]').to(:restart)
    end

    it do
      expect(chef_run).to enable_apache2_site('nova-placement')
    end

    it do
      expect(chef_run.apache2_site('nova-placement')).to notify('service[apache2]').to(:restart).immediately
    end
    context 'nova_placement false' do
      cached(:chef_run) do
        node.override['openstack']['compute']['nova_placement'] = false
        runner.converge(described_recipe)
      end

      it do
        expect(chef_run).to upgrade_package %w(python3-nova python3-placement libapache2-mod-wsgi-py3 )
      end

      it 'executes placement-api: nova-manage api_db sync' do
        expect(chef_run).to run_execute('placement-api: nova-manage api_db sync').with(
          timeout: 3600,
          user: 'placement',
          group: 'placement',
          command: 'placement-manage db sync'
        )
      end

      it do
        expect(chef_run).to disable_service 'placement-api'
        expect(chef_run).to stop_service 'placement-api'
      end

      it do
        expect(chef_run).to disable_apache2_site('nova-placement-api')
      end

      it do
        expect(chef_run).to install_apache2_install('openstack').with(listen: %w(127.0.0.1:8778))
      end

      it do
        expect(chef_run).to enable_apache2_module('wsgi')
      end

      it do
        expect(chef_run).to_not enable_apache2_module('ssl')
      end
      it do
        expect(chef_run).to create_template('/etc/apache2/sites-available/placement.conf').with(
          source: 'wsgi-template.conf.erb',
          variables: {
            ca_certs_path: '',
            cert_file: '',
            cert_required: false,
            chain_file: '',
            ciphers: '',
            daemon_process: 'placement-api',
            group: 'placement',
            key_file: '',
            log_dir: '/var/log/apache2',
            processes: 2,
            protocol: '',
            run_dir: '/var/lock',
            server_entry: '/usr/bin/placement-api',
            server_host: '127.0.0.1',
            server_port: '8778',
            threads: 1,
            user: 'placement',
            use_ssl: false,
          }
        )
      end
      [
        /<VirtualHost 127.0.0.1:8778>$/,
        /WSGIDaemonProcess placement-api processes=2 threads=1 user=placement group=placement display-name=%{GROUP}$/,
        /WSGIProcessGroup placement-api$/,
        %r{WSGIScriptAlias / /usr/bin/placement-api$},
        /WSGIApplicationGroup %{GLOBAL}$/,
        %r{ErrorLog /var/log/apache2/placement-api_error.log$},
        %r{CustomLog /var/log/apache2/placement-api_access.log combined$},
        %r{WSGISocketPrefix /var/lock$},
      ].each do |line|
        it do
          expect(chef_run).to render_file('/etc/apache2/sites-available/placement.conf').with_content(line)
        end
      end

      it do
        expect(chef_run.template('/etc/apache2/sites-available/placement.conf')).to \
          notify('service[apache2]').to(:restart)
      end

      it do
        expect(chef_run).to enable_apache2_site('placement')
      end

      it do
        expect(chef_run.apache2_site('placement')).to notify('service[apache2]').to(:restart).immediately
      end
    end
  end
end
