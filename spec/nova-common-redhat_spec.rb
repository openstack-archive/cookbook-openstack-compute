require "spec_helper"

describe "openstack-compute::nova-common" do
  describe "redhat" do
    before do
      compute_common_stubs
      @chef_run = ::ChefSpec::ChefRunner.new ::REDHAT_OPTS
      @chef_run.converge "openstack-compute::nova-common"
    end

    it "runs epel recipe" do
      expect(@chef_run).to include_recipe "yum::epel"
    end

    it "installs nova common packages" do
      expect(@chef_run).to upgrade_package "openstack-nova-common"
    end

    it "installs memcache python packages" do
      expect(@chef_run).to install_package "python-memcached"
    end
  end
end
