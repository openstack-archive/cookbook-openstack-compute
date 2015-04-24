# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-compute::nova-cert' do
  describe 'redhat' do
    let(:runner) { ChefSpec::SoloRunner.new(REDHAT_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'compute_stubs'

    it 'upgrades nova cert package' do
      expect(chef_run).to upgrade_package 'openstack-nova-cert'
    end

    it 'starts nova cert on boot' do
      expect(chef_run).to enable_service 'openstack-nova-cert'
    end
  end
end
