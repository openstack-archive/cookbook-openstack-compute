# encoding: UTF-8
require_relative 'spec_helper'

describe 'openstack-compute::client' do

  describe 'redhat' do

    let(:runner) { ChefSpec::Runner.new(REDHAT_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) do
      # TODO: Remove work around once https://github.com/customink/fauxhai/pull/77 merges
      node.set_unless['cpu']['total'] = 1
      runner.converge(described_recipe)
    end

    it 'installs packages' do
      expect(chef_run).to upgrade_package('python-novaclient')
    end
  end
end
