require_relative "spec_helper"

describe "openstack-compute::conductor" do
  before { compute_stubs }
  describe "redhat" do
    before do
      @chef_run = ::ChefSpec::Runner.new ::REDHAT_OPTS
      @chef_run.converge "openstack-compute::conductor"
    end

    expect_runs_nova_common_recipe

    it "installs conductor packages" do
      expect(@chef_run).to upgrade_package "openstack-nova-conductor"
    end

    it "starts nova-conductor on boot" do
      expect(@chef_run).to enable_service "openstack-nova-conductor"
    end

    it "starts nova-conductor" do
      expect(@chef_run).to start_service "openstack-nova-conductor"
    end
  end
end
