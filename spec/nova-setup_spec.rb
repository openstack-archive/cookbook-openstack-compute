# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-compute::nova-setup' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'compute_stubs'
    include_examples 'expect_runs_nova_common_recipe'

    it 'runs db migrations with default timeout' do
      expect(chef_run).to run_execute('nova-manage db sync').with(
        user: 'nova',
        group: 'nova',
        timeout: 3600
      )
    end

    it 'runs db migrations with timeout override' do
      node.override['openstack']['compute']['dbsync_timeout'] = 1234
      expect(chef_run).to run_execute('nova-manage db sync').with(
        user: 'nova',
        group: 'nova',
        timeout: 1234
      )
    end
  end
end
