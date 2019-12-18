# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-compute::placement_api' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    cached(:chef_run) { runner.converge(described_recipe) }

    include_context 'compute_stubs'

    it 'includes nova-common recipe' do
      expect(chef_run).to include_recipe 'openstack-compute::nova-common'
    end

    it 'upgrades package nova-placement-api' do
      expect(chef_run).to upgrade_package 'nova-placement-api'
    end

    it 'executes placement-api: nova-manage api_db sync' do
      expect(chef_run).to run_execute('placement-api: nova-manage api_db sync').with(
        timeout: 3600,
        user: 'nova',
        group: 'nova',
        command: 'nova-manage api_db sync'
      )
    end

    it 'disables nova-placement-api service' do
      expect(chef_run).to disable_service 'disable nova-placement-api service'
    end
    it do
      expect(chef_run).to nothing_execute('Clear nova-placement-api apache restart')
        .with(
          command: 'rm -f /var/chef/cache/nova-placement-api-apache-restarted'
        )
    end
    %w(
      /etc/nova/nova.conf
      /etc/apache2/sites-available/nova-placement-api.conf
    ).each do |f|
      it "#{f} notifies execute[Clear nova-placement-api apache restart]" do
        expect(chef_run.template(f)).to notify('execute[Clear nova-placement-api apache restart]').to(:run).immediately
      end
    end
    it do
      expect(chef_run).to run_execute('nova-placement-api apache restart')
        .with(
          command: 'touch /var/chef/cache/nova-placement-api-apache-restarted',
          creates: '/var/chef/cache/nova-placement-api-apache-restarted'
        )
    end
    it do
      expect(chef_run.execute('nova-placement-api apache restart')).to notify('service[apache2]').to(:restart).immediately
    end
  end
end
