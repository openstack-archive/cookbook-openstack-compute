require_relative "spec_helper"

describe "openstack-compute::ceilometer-agent-central" do
  before { compute_stubs }
  describe "opensuse" do
    before do
      @chef_run = ::ChefSpec::ChefRunner.new ::OPENSUSE_OPTS
      @chef_run.converge "openstack-compute::ceilometer-agent-central"
    end

    it "installs the ceilometer agent-central package" do
      expect(@chef_run).to install_package "openstack-ceilometer-agent-central"
    end

    it "starts the agent-central service" do
      expect(@chef_run).to start_service "openstack-ceilometer-agent-central"
    end
  end
end
