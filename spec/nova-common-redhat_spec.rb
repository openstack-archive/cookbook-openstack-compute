require_relative 'spec_helper'

describe 'openstack-compute::nova-common' do
  ALL_RHEL.each do |p|
    context "redhat #{p[:version]}" do
      let(:runner) { ChefSpec::SoloRunner.new(p) }
      let(:node) { runner.node }
      cached(:chef_run) { runner.converge(described_recipe) }

      include_context 'compute_stubs'
      include_examples 'expect_creates_nova_state_dir'
      include_examples 'expect_creates_nova_lock_dir'

      it do
        expect(chef_run).to upgrade_package %w(openstack-nova-common)
      end

      case p
      when REDHAT_7
        it do
          expect(chef_run).to upgrade_package 'MySQL-python'
        end

        it do
          expect(chef_run).to upgrade_package 'python-memcached'
        end
      when REDHAT_8
        it do
          expect(chef_run).to upgrade_package 'python3-PyMySQL'
        end

        it do
          expect(chef_run).to upgrade_package 'python3-memcached'
        end
      end
    end
  end
end
