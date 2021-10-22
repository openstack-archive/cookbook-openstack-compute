require_relative 'spec_helper'

describe 'openstack-compute::spiceproxy' do
  ALL_RHEL.each do |p|
    context "redhat #{p[:version]}" do
      let(:runner) { ChefSpec::SoloRunner.new(p) }
      let(:node) { runner.node }
      cached(:chef_run) { runner.converge(described_recipe) }

      include_context 'compute_stubs'
      include_examples 'expect_runs_nova_common_recipe'
      include_examples 'expect_creates_nova_state_dir'
      include_examples 'expect_creates_nova_lock_dir'

      it do
        expect(chef_run).to upgrade_package %w(openstack-nova-spicehtml5proxy spice-html5)
      end

      it 'starts nova spicehtml5proxy' do
        expect(chef_run).to start_service('openstack-nova-spicehtml5proxy')
      end

      it 'starts nova spicehtml5proxy on boot' do
        expect(chef_run).to enable_service('openstack-nova-spicehtml5proxy')
      end
    end
  end
end
