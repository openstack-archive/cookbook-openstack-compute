require_relative "spec_helper"

describe "openstack-compute::ceilometer-collector" do
  before { compute_stubs }
  describe "opensuse" do
    before do
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
