require_relative 'spec_helper'

describe 'openstack-compute::compute' do
  describe 'redhat' do
    let(:runner) { ChefSpec::SoloRunner.new(REDHAT_OPTS) }
    let(:node) { runner.node }
    cached(:chef_run) { runner.converge(described_recipe) }

    include_context 'compute_stubs'
    include_examples 'expect_runs_nova_common_recipe'
    include_examples 'expect_creates_nova_state_dir'
    include_examples 'expect_creates_nova_lock_dir'
    include_examples 'expect_creates_nova_instances_dir'
    include_examples 'expect_volume_packages'

    context "does not upgrade kvm when virt_type is 'kvm'" do
      cached(:chef_run) do
        node.override['openstack']['compute']['libvirt']['virt_type'] = 'kvm'
        runner.converge(described_recipe)
      end
      it do
        expect(chef_run).to_not upgrade_package('nova-compute-kvm')
      end
    end

    context "does not upgrade qemu when virt_type is 'qemu'" do
      cached(:chef_run) do
        node.override['openstack']['compute']['libvirt']['virt_type'] = 'qemu'
        runner.converge(described_recipe)
      end
      it do
        expect(chef_run).to_not upgrade_package('nova-compute-qemu')
      end
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
