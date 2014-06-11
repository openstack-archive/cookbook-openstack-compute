# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-compute::api-ec2' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::Runner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'compute_stubs'
    include_examples 'expect_runs_nova_common_recipe'
    include_examples 'expect_creates_nova_state_dir'
    include_examples 'expect_creates_nova_lock_dir'

    include_examples 'expect_upgrades_python_keystoneclient'

    it 'upgrade ec2 api package' do
      expect(chef_run).to upgrade_package 'nova-api-ec2'
    end

    it 'starts ec2 api on boot' do
      expect(chef_run).to enable_service 'nova-api-ec2'
    end

    expect_creates_api_paste 'service[nova-api-ec2]'
  end
end
