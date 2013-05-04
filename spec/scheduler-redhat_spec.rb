require "spec_helper"

describe "nova::scheduler" do
  describe "redhat" do
    before do
      nova_common_stubs
      @chef_run = ::ChefSpec::ChefRunner.new ::REDHAT_OPTS
      @chef_run.converge "nova::scheduler"
    end

    it "installs nova scheduler packages" do
      expect(@chef_run).to upgrade_package "openstack-nova-scheduler"
    end

    it "starts nova scheduler" do
      expect(@chef_run).to start_service "openstack-nova-scheduler"
    end

    it "starts nova scheduler on boot" do
      expect(@chef_run).to set_service_to_start_on_boot "openstack-nova-scheduler"
    end
  end
end
