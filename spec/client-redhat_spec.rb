# encoding: UTF-8
require_relative 'spec_helper'

describe 'openstack-compute::client' do
  describe 'redhat' do
    let(:runner) { ChefSpec::SoloRunner.new(REDHAT_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) do
      runner.converge(described_recipe)
    end

    it 'upgrades python-novaclient package' do
      expect(chef_run).to upgrade_package('python-novaclient')
    end
  end
end
