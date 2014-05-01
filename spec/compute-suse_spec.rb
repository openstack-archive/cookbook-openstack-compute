# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-compute::compute' do
  describe 'suse' do
    let(:runner) { ChefSpec::Runner.new(SUSE_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'compute_stubs'

    it 'upgrades nfs client packages' do
      expect(chef_run).to upgrade_package 'nfs-utils'
      expect(chef_run).not_to upgrade_package 'nfs-utils-lib'
    end
  end
end
