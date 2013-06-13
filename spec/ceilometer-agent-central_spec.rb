require_relative "spec_helper"

describe "openstack-compute::ceilometer-agent-central" do
  before { compute_stubs }
  describe "ubuntu" do
    before do
      @chef_run = ::ChefSpec::ChefRunner.new ::UBUNTU_OPTS
      @chef_run.converge "openstack-compute::ceilometer-agent-central"
    end

    expect_runs_ceilometer_common_recipe

    it "starts ceilometer-agent-central service" do
      expect(@chef_run).to start_service("ceilometer-agent-central")
    end
  end
end
