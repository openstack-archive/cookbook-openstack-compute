# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-compute::vncproxy' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::Runner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'compute_stubs'
    include_examples 'expect_runs_nova_common_recipe'

    it 'installs nova vncproxy packages' do
      expect(chef_run).to upgrade_package 'novnc'
      expect(chef_run).to upgrade_package 'websockify'
      expect(chef_run).to upgrade_package 'nova-novncproxy'
    end

    it 'installs nova consoleauth packages' do
      expect(chef_run).to upgrade_package 'nova-consoleauth'
    end

    it 'starts nova vncproxy' do
      expect(chef_run).to start_service 'nova-novncproxy'
    end

    it 'starts nova vncproxy on boot' do
      expect(chef_run).to enable_service 'nova-novncproxy'
    end

    it 'starts nova consoleauth' do
      expect(chef_run).to start_service 'nova-consoleauth'
    end

    it 'starts nova consoleauth on boot' do
      expect(chef_run).to enable_service 'nova-consoleauth'
    end
  end
end
