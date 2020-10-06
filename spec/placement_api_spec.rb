require_relative 'spec_helper'

describe 'openstack-compute::placement_api' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    cached(:chef_run) { runner.converge(described_recipe) }

    include_context 'compute_stubs'

    include_examples 'expect_runs_nova_apache_recipe'

    it do
      expect(chef_run).to upgrade_package %w(python3-placement libapache2-mod-wsgi-py3)
    end

    it do
      expect(chef_run).to run_execute('placement-manage db sync').with(
        user: 'placement',
        group: 'placement'
      )
    end

    it do
      expect(chef_run).to disable_service 'placement-api'
      expect(chef_run).to stop_service 'placement-api'
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

    describe 'placement.conf' do
      let(:file) { chef_run.template('/etc/placement/placement.conf') }
      it do
        expect(chef_run).to create_template(file.name).with(
          source: 'openstack-service.conf.erb',
          cookbook: 'openstack-common',
          owner: 'placement',
          group: 'placement',
          mode: '640',
          sensitive: true
        )
      end

      it do
        expect(chef_run.template('/etc/placement/placement.conf')).to notify('service[apache2]').to(:restart)
      end

      it '[DEFAULT]' do
        [
          %r{^log_dir = /var/log/placement$},
          %r{^state_path = /var/lib/placement$},
          %r{^transport_url = rabbit://guest:mypass@127.0.0.1:5672$},
        ].each do |line|
          expect(chef_run).to render_config_file(file.name).with_section_content('DEFAULT', line)
        end
      end
      it '[placement_database]' do
        [
          %r{^connection = mysql\+pymysql://placement:placement_db_pass@127.0.0.1:3306/placement\?charset=utf8$},
        ].each do |line|
          expect(chef_run).to render_config_file(file.name).with_section_content('placement_database', line)
        end
      end
      it '[keystone_authtoken]' do
        [
          /^auth_type = password$/,
          /^username = placement$/,
          /^user_domain_name = Default$/,
          /^project_domain_name = Default$/,
          /^project_name = service$/,
          %r{^auth_url = http://127.0.0.1:5000/v3$},
          %r{^www_authenticate_uri = http://127.0.0.1:5000/v3$},
          /^password = placement-pass$/,
        ].each do |line|
          expect(chef_run).to render_config_file(file.name).with_section_content('keystone_authtoken', line)
        end
      end
      it '[api]' do
        [
          /^auth_strategy = keystone$/,
        ].each do |line|
          expect(chef_run).to render_config_file(file.name).with_section_content('api', line)
        end
      end
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
          threads: 10,
          user: 'placement',
          use_ssl: false,
        }
      )
    end
    [
      /<VirtualHost 127.0.0.1:8778>$/,
      /WSGIDaemonProcess placement-api processes=2 threads=10 user=placement group=placement display-name=%{GROUP}$/,
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
        expect(chef_run).to_not render_file('/etc/apache2/sites-available/placement.conf').with_content(line)
      end
    end

    context 'Enable SSL' do
      cached(:chef_run) do
        node.override['openstack']['placement']['ssl']['enabled'] = true
        node.override['openstack']['placement']['ssl']['certfile'] = 'ssl.cert'
        node.override['openstack']['placement']['ssl']['keyfile'] = 'ssl.key'
        node.override['openstack']['placement']['ssl']['ca_certs_path'] = 'ca_certs_path'
        node.override['openstack']['placement']['ssl']['protocol'] = 'ssl_protocol_value'
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
          expect(chef_run).to render_file('/etc/apache2/sites-available/placement.conf').with_content(line)
        end
      end
      [
        /SSLCipherSuite/,
        /SSLCertificateChainFile/,
        /SSLVerifyClient require/,
      ].each do |line|
        it do
          expect(chef_run).to_not render_file('/etc/apache2/sites-available/placement.conf').with_content(line)
        end
      end
      context 'Enable chainfile, ciphers & cert_required' do
        cached(:chef_run) do
          node.override['openstack']['placement']['ssl']['enabled'] = true
          node.override['openstack']['placement']['ssl']['ciphers'] = 'ssl_ciphers_value'
          node.override['openstack']['placement']['ssl']['chainfile'] = 'chainfile'
          node.override['openstack']['placement']['ssl']['cert_required'] = true
          runner.converge(described_recipe)
        end
        [
          /SSLCipherSuite ssl_ciphers_value$/,
          /SSLCertificateChainFile chainfile$/,
          /SSLVerifyClient require/,
        ].each do |line|
          it do
            expect(chef_run).to render_file('/etc/apache2/sites-available/placement.conf').with_content(line)
          end
        end
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
