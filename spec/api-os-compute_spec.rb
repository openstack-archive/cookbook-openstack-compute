# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-compute::api-os-compute' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    cached(:chef_run) { runner.converge(described_recipe) }

    include_context 'compute_stubs'
    include_examples 'expect_runs_nova_common_recipe'
    include_examples 'expect_creates_nova_state_dir'
    include_examples 'expect_creates_nova_lock_dir'
    include_examples 'expect_creates_api_paste_template'

    it do
      expect(chef_run).to run_execute('nova-manage api_db sync')
        .with(
          timeout: 3600,
          user: 'nova',
          group: 'nova',
          command: 'nova-manage api_db sync'
        )
    end

    it do
      expect(chef_run).to upgrade_package %w(python3-nova nova-api)
    end

    it do
      expect(chef_run).to disable_service 'nova-api-os-compute'
      expect(chef_run).to stop_service 'nova-api-os-compute'
    end
    it do
      expect(chef_run).to install_apache2_install('openstack').with(listen: '127.0.0.1:8774')
    end

    it do
      expect(chef_run).to enable_apache2_module('wsgi')
    end

    it do
      expect(chef_run).to_not enable_apache2_module('ssl')
    end

    it do
      expect(chef_run).to create_template('/etc/apache2/sites-available/nova-api.conf').with(
        source: 'wsgi-template.conf.erb',
        variables: {
          ca_certs_path: '',
          cert_file: '',
          cert_required: false,
          chain_file: '',
          ciphers: '',
          daemon_process: 'nova-api',
          group: 'nova',
          key_file: '',
          log_dir: '/var/log/apache2',
          processes: 6,
          protocol: '',
          run_dir: '/var/lock/apache2',
          server_entry: '/usr/bin/nova-api-wsgi',
          server_host: '127.0.0.1',
          server_port: '8774',
          threads: 1,
          user: 'nova',
          use_ssl: false,
        }
      )
    end
    [
      /<VirtualHost 127.0.0.1:8774>$/,
      /WSGIDaemonProcess nova-api processes=6 threads=1 user=nova group=nova display-name=%{GROUP}$/,
      /WSGIProcessGroup nova-api$/,
      %r{WSGIScriptAlias / /usr/bin/nova-api-wsgi$},
      /WSGIApplicationGroup %{GLOBAL}$/,
      %r{ErrorLog /var/log/apache2/nova-api_error.log$},
      %r{CustomLog /var/log/apache2/nova-api_access.log combined$},
      %r{WSGISocketPrefix /var/lock/apache2$},
    ].each do |line|
      it do
        expect(chef_run).to render_file('/etc/apache2/sites-available/nova-api.conf').with_content(line)
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
        expect(chef_run).to_not render_file('/etc/apache2/sites-available/nova-api.conf').with_content(line)
      end
    end

    context 'Enable SSL' do
      cached(:chef_run) do
        node.override['openstack']['compute']['api']['ssl']['enabled'] = true
        node.override['openstack']['compute']['api']['ssl']['certfile'] = 'ssl.cert'
        node.override['openstack']['compute']['api']['ssl']['keyfile'] = 'ssl.key'
        node.override['openstack']['compute']['api']['ssl']['ca_certs_path'] = 'ca_certs_path'
        node.override['openstack']['compute']['api']['ssl']['protocol'] = 'ssl_protocol_value'
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
          expect(chef_run).to render_file('/etc/apache2/sites-available/nova-api.conf').with_content(line)
        end
      end
      [
        /SSLCipherSuite/,
        /SSLCertificateChainFile/,
        /SSLVerifyClient require/,
      ].each do |line|
        it do
          expect(chef_run).to_not render_file('/etc/apache2/sites-available/nova-api.conf').with_content(line)
        end
      end
      context 'Enable chainfile, ciphers & cert_required' do
        cached(:chef_run) do
          node.override['openstack']['compute']['api']['ssl']['enabled'] = true
          node.override['openstack']['compute']['api']['ssl']['ciphers'] = 'ssl_ciphers_value'
          node.override['openstack']['compute']['api']['ssl']['chainfile'] = 'chainfile'
          node.override['openstack']['compute']['api']['ssl']['cert_required'] = true
          runner.converge(described_recipe)
        end
        [
          /SSLCipherSuite ssl_ciphers_value$/,
          /SSLCertificateChainFile chainfile$/,
          /SSLVerifyClient require/,
        ].each do |line|
          it do
            expect(chef_run).to render_file('/etc/apache2/sites-available/nova-api.conf').with_content(line)
          end
        end
      end
    end

    it do
      expect(chef_run.template('/etc/apache2/sites-available/nova-api.conf')).to \
        notify('service[apache2]').to(:restart)
    end

    it do
      expect(chef_run).to enable_apache2_site('nova-api')
    end

    it do
      expect(chef_run.apache2_site('nova-api')).to notify('service[apache2]').to(:restart).immediately
    end
  end
end
