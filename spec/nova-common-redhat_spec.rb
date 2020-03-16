# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-compute::nova-common' do
  describe 'redhat' do
    let(:runner) { ChefSpec::SoloRunner.new(REDHAT_OPTS) }
    let(:node) { runner.node }
    cached(:chef_run) { runner.converge(described_recipe) }

    include_context 'compute_stubs'
    include_examples 'expect_creates_nova_state_dir'
    include_examples 'expect_creates_nova_lock_dir'

    it do
      expect(chef_run).to upgrade_package %w(openstack-nova-common mod_wsgi)
    end

    it do
      expect(chef_run).to upgrade_package 'MySQL-python'
    end

    it do
      expect(chef_run).to upgrade_package 'python-memcached'
    end
  end
end
