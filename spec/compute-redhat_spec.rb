require "spec_helper"

describe "nova::compute" do
  describe "redhat" do
    before do
      nova_common_stubs
      @chef_run = ::ChefSpec::ChefRunner.new ::REDHAT_OPTS
      @chef_run.converge "nova::compute"
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
      expect(@chef_run).to set_service_to_start_on_boot "openstack-nova-compute"
    end
  end
end
