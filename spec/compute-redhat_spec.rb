# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-compute::compute' do
  describe 'redhat' do
    let(:runner) { ChefSpec::SoloRunner.new(REDHAT_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'compute_stubs'
    include_examples 'expect_runs_nova_common_recipe'
    include_examples 'expect_creates_nova_state_dir'
    include_examples 'expect_creates_nova_lock_dir'
    include_examples 'expect_creates_nova_instances_dir'
    include_examples 'expect_volume_packages'

    it "does not upgrade kvm when virt_type is 'kvm'" do
      node.set['openstack']['compute']['libvirt']['virt_type'] = 'kvm'

      expect(chef_run).to_not upgrade_package('nova-compute-kvm')
    end

    it "does not upgrade qemu when virt_type is 'qemu'" do
      node.set['openstack']['compute']['libvirt']['virt_type'] = 'qemu'

      expect(chef_run).to_not upgrade_package('nova-compute-qemu')
    end

    it 'upgrades nova compute package' do
      expect(chef_run).to upgrade_package('openstack-nova-compute')
    end

    it 'starts nova compute on boot' do
      expected = 'openstack-nova-compute'
      expect(chef_run).to enable_service(expected)
    end

    it 'starts nova compute' do
      expect(chef_run).to start_service('openstack-nova-compute')
    end
  end
end
