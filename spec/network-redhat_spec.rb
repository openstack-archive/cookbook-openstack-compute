require "spec_helper"

describe "nova::network" do
  describe "redhat" do
    before do
      nova_common_stubs
      @chef_run = ::ChefSpec::ChefRunner.new(
        :platform  => "redhat",
        :log_level => ::LOG_LEVEL
      ).converge "nova::network"
    end

    it "installs nova network packages" do
      expect(@chef_run).to upgrade_package "iptables"
      expect(@chef_run).to upgrade_package "openstack-nova-network"
    end

    it "starts nova network on boot" do
      expect(@chef_run).to set_service_to_start_on_boot "openstack-nova-network"
    end
  end
end
