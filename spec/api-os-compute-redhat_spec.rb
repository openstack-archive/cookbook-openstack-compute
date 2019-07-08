# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-compute::api-os-compute' do
  describe 'redhat' do
    let(:runner) { ChefSpec::SoloRunner.new(REDHAT_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'compute_stubs'
    include_examples 'expect_runs_nova_common_recipe'
    include_examples 'expect_creates_nova_state_dir'
    include_examples 'expect_creates_nova_lock_dir'

    it 'executes nova-manage api_db sync' do
      expect(chef_run).to run_execute('nova-manage api_db sync')
        .with(timeout: 3600,
              user: 'nova',
              group: 'nova',
              command: 'nova-manage api_db sync')
    end

    it 'upgrades openstack api packages' do
      expect(chef_run).to upgrade_package 'openstack-nova-api'
    end

    it 'disables openstack api on boot' do
      expect(chef_run).to disable_service 'openstack-nova-api'
    end

    it 'stops openstack api now' do
      expect(chef_run).to stop_service 'openstack-nova-api'
    end
    it do
      expect(chef_run).to nothing_execute('Clear nova-api apache restart')
        .with(
          command: 'rm -f /var/chef/cache/nova-api-apache-restarted'
        )
    end
    %w(
      /etc/nova/nova.conf
      /etc/nova/api-paste.ini
      /etc/httpd/sites-available/nova-api.conf
    ).each do |f|
      it "#{f} notifies execute[Clear nova-api apache restart]" do
        expect(chef_run.template(f)).to notify('execute[Clear nova-api apache restart]').to(:run).immediately
      end
    end
    it do
      expect(chef_run).to run_execute('nova-api apache restart')
        .with(
          command: 'touch /var/chef/cache/nova-api-apache-restarted',
          creates: '/var/chef/cache/nova-api-apache-restarted'
        )
    end
    it do
      expect(chef_run.execute('nova-api apache restart')).to notify('execute[nova-api: restore-selinux-context]').to(:run).immediately
    end
    it do
      expect(chef_run.execute('nova-api apache restart')).to notify('service[apache2]').to(:restart).immediately
    end
  end
end
