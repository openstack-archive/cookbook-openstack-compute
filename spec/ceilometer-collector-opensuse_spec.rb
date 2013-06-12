require "spec_helper"

describe "openstack-compute::ceilometer-collector" do
  describe "opensuse" do
    before do
      compute_stubs
      @chef_run = ::ChefSpec::ChefRunner.new ::OPENSUSE_OPTS
      @chef_run.converge "openstack-compute::ceilometer-collector"
    end

    it "installs the ceilometer collector package" do
      expect(@chef_run).to install_package "openstack-ceilometer-collector"
    end

    it "starts the collector service" do
      expect(@chef_run).to start_service "openstack-ceilometer-collector"
    end
  end
end
