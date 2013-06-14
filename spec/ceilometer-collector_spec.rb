require_relative "spec_helper"

describe "openstack-compute::ceilometer-collector" do
  before { compute_stubs }
  describe "ubuntu" do
    before do
      @chef_run = ::ChefSpec::ChefRunner.new ::UBUNTU_OPTS
      @chef_run.converge "openstack-compute::ceilometer-collector"
    end

    expect_runs_ceilometer_common_recipe

    it "starts ceilometer-collector service" do
      expect(@chef_run).to start_service("ceilometer-collector")
    end
  end
end
