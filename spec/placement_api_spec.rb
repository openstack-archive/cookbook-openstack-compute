# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-compute::placement_api' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'compute_stubs'

    it "includes nova-common recipe" do
      expect(chef_run).to include_recipe 'openstack-compute::nova-common'
    end

    it "upgrades package nova-placement-api" do
      expect(chef_run).to upgrade_package 'nova-placement-api'
    end

    it "executes placement-api: nova-manage api_db sync" do
      expect(chef_run).to run_execute('placement-api: nova-manage api_db sync').with(
        timeout: 3600,
        user: 'nova',
        group: 'nova',
        command: 'nova-manage api_db sync'
      )
    end

    it "disables nova-placement-api service" do
      expect(chef_run).to disable_service 'disable nova-placement-api service'
    end
  end
end
