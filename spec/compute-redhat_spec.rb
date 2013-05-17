require "spec_helper"

describe "openstack-compute::compute" do
  describe "redhat" do
    before do
      compute_common_stubs
      @chef_run = ::ChefSpec::ChefRunner.new ::REDHAT_OPTS
      @chef_run.converge "openstack-compute::compute"
    end

    it "does not install kvm when virt_type is 'kvm'" do
      pending "TODO: how to test this"
    end

    it "does not install qemu when virt_type is 'qemu'" do
      pending "TODO: how to test this"
    end

    it "installs nova compute packages" do
      expect(@chef_run).to upgrade_package "openstack-nova-compute"
    end

    it "starts nova compute on boot" do
      expected = "openstack-nova-compute"
      expect(@chef_run).to set_service_to_start_on_boot expected
    end
  end
end
