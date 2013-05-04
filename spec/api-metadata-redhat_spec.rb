require "spec_helper"

describe "nova::api-metadata" do
  describe "redhat" do
    before do
      nova_common_stubs
      @chef_run = ::ChefSpec::ChefRunner.new ::REDHAT_OPTS
      @chef_run.converge "nova::api-metadata"
    end

    it "installs metadata api packages" do
      expect(@chef_run).to upgrade_package "openstack-nova-api"
    end

    it "starts metadata api on boot" do
      expect(@chef_run).to set_service_to_start_on_boot "openstack-nova-api"
    end
  end
end
