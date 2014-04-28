# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-compute::conductor' do
  describe 'redhat' do
    let(:runner) { ChefSpec::Runner.new(REDHAT_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'compute_stubs'

    it 'installs conductor packages' do
      expect(chef_run).to upgrade_package 'openstack-nova-conductor'
    end

    it 'starts nova-conductor on boot' do
      expect(chef_run).to enable_service 'openstack-nova-conductor'
    end

    it 'starts nova-conductor' do
      expect(chef_run).to start_service 'openstack-nova-conductor'
    end
  end
end
