require "spec_helper"

describe "openstack-compute::ceilometer-api" do
  describe "opensuse" do
    before do
      compute_stubs
      @chef_run = ::ChefSpec::ChefRunner.new ::OPENSUSE_OPTS
      @chef_run.converge "openstack-compute::ceilometer-api"
    end

    expect_runs_ceilometer_common_recipe

    it "starts openstack-ceilometer-api service" do
      expect(@chef_run).to start_service("openstack-ceilometer-api")
    end

    describe "/etc/apache2/conf.d/ceilometer-api.conf" do
      before do
        # XXX this should be hardcoded to /etc/apache2/... instead of
        # httpd, but the upstream cookbook is broken for SUSE
        @file = @chef_run.template "/etc/httpd/conf.d/ceilometer-api.conf"
      end

      it "has proper owner" do
        expect(@file).to be_owned_by "root", "root"
      end
    end

    it "installs the apache2 package" do
      expect(@chef_run).to install_package("openstack-ceilometer-api")
    end
  end
end
