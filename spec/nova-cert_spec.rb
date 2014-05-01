# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-compute::nova-cert' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::Runner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'compute_stubs'
    include_examples 'expect_runs_nova_common_recipe'

    it 'upgrades nova cert package' do
      expect(chef_run).to upgrade_package('nova-cert')
    end

    it 'starts nova cert on boot' do
      expect(chef_run).to enable_service('nova-cert')
    end
  end
end
