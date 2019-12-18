# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-compute::api-metadata' do
  describe 'redhat' do
    let(:runner) { ChefSpec::SoloRunner.new(REDHAT_OPTS) }
    let(:node) { runner.node }
    cached(:chef_run) { runner.converge(described_recipe) }

    include_context 'compute_stubs'
    include_examples 'expect_runs_nova_common_recipe'
    include_examples 'expect_creates_nova_state_dir'
    include_examples 'expect_creates_nova_lock_dir'

    it 'upgrades metadata api packages' do
      expect(chef_run).to upgrade_package 'openstack-nova-api'
    end

    it 'disables metadata api on boot' do
      expect(chef_run).to disable_service 'nova-api-metadata'
    end

    it 'stops metadata api now' do
      expect(chef_run).to stop_service 'nova-api-metadata'
    end
    it do
      expect(chef_run).to nothing_execute('Clear nova-metadata apache restart')
        .with(
          command: 'rm -f /var/chef/cache/nova-metadata-apache-restarted'
        )
    end
    %w(
      /etc/nova/nova.conf
      /etc/nova/api-paste.ini
      /etc/httpd/sites-available/nova-metadata.conf
    ).each do |f|
      it "#{f} notifies execute[Clear nova-metadata apache restart]" do
        expect(chef_run.template(f)).to notify('execute[Clear nova-metadata apache restart]').to(:run).immediately
      end
    end
    it do
      expect(chef_run).to run_execute('nova-metadata apache restart')
        .with(
          command: 'touch /var/chef/cache/nova-metadata-apache-restarted',
          creates: '/var/chef/cache/nova-metadata-apache-restarted'
        )
    end
    it do
      expect(chef_run.execute('nova-metadata apache restart')).to notify('execute[nova-metadata: restore-selinux-context]').to(:run).immediately
    end
    it do
      expect(chef_run.execute('nova-metadata apache restart')).to notify('service[apache2]').to(:restart).immediately
    end
  end
end
