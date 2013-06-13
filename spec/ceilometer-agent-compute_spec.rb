require_relative "spec_helper"

describe "openstack-compute::ceilometer-agent-compute" do
  describe "ubuntu" do
    before do
      compute_stubs
      @chef_run = ::ChefSpec::ChefRunner.new ::UBUNTU_OPTS
      @chef_run.converge "openstack-compute::ceilometer-agent-compute"
    end

    expect_runs_ceilometer_common_recipe

    it "starts ceilometer-agent-compute service" do
      expect(@chef_run).to start_service("ceilometer-agent-compute")
    end
  end
end
