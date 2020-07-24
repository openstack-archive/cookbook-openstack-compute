# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-compute::_nova_apache' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    cached(:chef_run) { runner.converge(described_recipe) }

    include_context 'compute_stubs'

    it do
      expect(chef_run).to include_recipe('openstack-compute::nova-common')
    end

    it do
      expect(chef_run.service('apache2')).to \
        subscribe_to('template[/etc/nova/nova.conf]').on(:restart)
    end
  end
end
