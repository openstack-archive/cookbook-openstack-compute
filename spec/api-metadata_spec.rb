# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-compute::api-metadata' do
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
      expect(chef_run).to upgrade_package %w(python3-nova nova-api-metadata)
    end

    it do
      expect(chef_run).to disable_service 'nova-api-metadata'
      expect(chef_run).to stop_service 'nova-api-metadata'
    end

    it do
      expect(chef_run).to install_apache2_install('openstack').with(listen: %w(127.0.0.1:8775))
    end

    it do
      expect(chef_run).to enable_apache2_module('wsgi')
    end

    it do
      expect(chef_run).to_not enable_apache2_module('ssl')
    end

    it do
      expect(chef_run).to create_template('/etc/apache2/sites-available/nova-metadata.conf').with(
        source: 'wsgi-template.conf.erb',
        variables: {
          ca_certs_path: '',
          cert_file: '',
          cert_required: false,
          chain_file: '',
          ciphers: '',
          daemon_process: 'nova-metadata',
          group: 'nova',
          key_file: '',
          log_dir: '/var/log/apache2',
          processes: 2,
          protocol: '',
          run_dir: '/var/lock/apache2',
          server_entry: '/usr/bin/nova-metadata-wsgi',
          server_host: '127.0.0.1',
          server_port: '8775',
          threads: 10,
          user: 'nova',
          use_ssl: false,
        }
      )
    end
    [
      /<VirtualHost 127.0.0.1:8775>$/,
      /WSGIDaemonProcess nova-metadata processes=2 threads=10 user=nova group=nova display-name=%{GROUP}$/,
      /WSGIProcessGroup nova-metadata$/,
      %r{WSGIScriptAlias / /usr/bin/nova-metadata-wsgi$},
      /WSGIApplicationGroup %{GLOBAL}$/,
      %r{ErrorLog /var/log/apache2/nova-metadata_error.log$},
      %r{CustomLog /var/log/apache2/nova-metadata_access.log combined$},
      %r{WSGISocketPrefix /var/lock/apache2$},
    ].each do |line|
      it do
        expect(chef_run).to render_file('/etc/apache2/sites-available/nova-metadata.conf').with_content(line)
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
        expect(chef_run).to_not render_file('/etc/apache2/sites-available/nova-metadata.conf').with_content(line)
      end
    end

    context 'Enable SSL' do
      cached(:chef_run) do
        node.override['openstack']['compute']['metadata']['ssl']['enabled'] = true
        node.override['openstack']['compute']['metadata']['ssl']['certfile'] = 'ssl.cert'
        node.override['openstack']['compute']['metadata']['ssl']['keyfile'] = 'ssl.key'
        node.override['openstack']['compute']['metadata']['ssl']['ca_certs_path'] = 'ca_certs_path'
        node.override['openstack']['compute']['metadata']['ssl']['protocol'] = 'ssl_protocol_value'
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
          expect(chef_run).to render_file('/etc/apache2/sites-available/nova-metadata.conf').with_content(line)
        end
      end
      [
        /SSLCipherSuite/,
        /SSLCertificateChainFile/,
        /SSLVerifyClient require/,
      ].each do |line|
        it do
          expect(chef_run).to_not render_file('/etc/apache2/sites-available/nova-metadata.conf').with_content(line)
        end
      end
      context 'Enable chainfile, ciphers & cert_required' do
        cached(:chef_run) do
          node.override['openstack']['compute']['metadata']['ssl']['enabled'] = true
          node.override['openstack']['compute']['metadata']['ssl']['ciphers'] = 'ssl_ciphers_value'
          node.override['openstack']['compute']['metadata']['ssl']['chainfile'] = 'chainfile'
          node.override['openstack']['compute']['metadata']['ssl']['cert_required'] = true
          runner.converge(described_recipe)
        end
        [
          /SSLCipherSuite ssl_ciphers_value$/,
          /SSLCertificateChainFile chainfile$/,
          /SSLVerifyClient require/,
        ].each do |line|
          it do
            expect(chef_run).to render_file('/etc/apache2/sites-available/nova-metadata.conf').with_content(line)
          end
        end
      end
    end

    it do
      expect(chef_run.template('/etc/apache2/sites-available/nova-metadata.conf')).to \
        notify('service[apache2]').to(:restart)
    end

    it do
      expect(chef_run).to enable_apache2_site('nova-metadata')
    end

    it do
      expect(chef_run.apache2_site('nova-metadata')).to notify('service[apache2]').to(:restart).immediately
    end
  end
end
