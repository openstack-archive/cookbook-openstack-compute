# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-compute::docker-setup' do
  describe 'redhat' do
    let(:runner) { ChefSpec::SoloRunner.new(REDHAT_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    it 'upgrades python-devel package' do
      expect(chef_run).to upgrade_package 'python-devel'
    end
  end
end
