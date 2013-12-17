require_relative "spec_helper"

describe "openstack-compute::vncproxy" do
  before { compute_stubs }
  describe "redhat" do
    before do
      @chef_run = ::ChefSpec::Runner.new ::REDHAT_OPTS
      @chef_run.converge "openstack-compute::vncproxy"
    end

    it "starts nova vncproxy on boot" do
      expected = "openstack-nova-novncproxy"
      expect(@chef_run).to enable_service expected
    end

    it "starts nova consoleauth" do
      expect(@chef_run).to start_service "openstack-nova-consoleauth"
    end

    it "starts nova consoleauth on boot" do
      expected = "openstack-nova-consoleauth"
      expect(@chef_run).to enable_service expected
    end
  end
end
