require "spec_helper"

describe "nova::vncproxy" do
  describe "redhat" do
    before do
      nova_common_stubs
      @chef_run = ::ChefSpec::ChefRunner.new(
        :platform  => "redhat",
        :log_level => ::LOG_LEVEL
      ).converge "nova::vncproxy"
    end

    it "starts nova vncproxy on boot" do
      expect(@chef_run).to set_service_to_start_on_boot "openstack-nova-novncproxy"
    end

    it "starts nova consoleauth" do
      expect(@chef_run).to start_service "openstack-nova-console"
    end

    it "starts nova consoleauth on boot" do
      expect(@chef_run).to set_service_to_start_on_boot "openstack-nova-console"
    end
  end
end
