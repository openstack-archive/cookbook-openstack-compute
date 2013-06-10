require_relative "spec_helper"

describe "openstack-compute::ceilometer-common" do
  describe "opensuse" do
    before do
      compute_stubs
      @chef_run = ::ChefSpec::ChefRunner.new ::OPENSUSE_OPTS
      @chef_run.converge "openstack-compute::ceilometer-common"
    end

    it "installs the ceilometer common packages" do
      expect(@chef_run).to install_package "openstack-ceilometer"
    end

    it "does not include recipe python-pip" do
      expect(@chef_run).not_to include_recipe "python::pip"
    end

    it "creates ceilometer.conf without changing ownership" do
      conf = @chef_run.template "/etc/ceilometer/ceilometer.conf"
      expect(conf).to be_owned_by(nil, nil)
    end

    it "creates the policy.json file without changing ownership" do
      policy = @chef_run.cookbook_file "/etc/ceilometer/policy.json"
      expect(policy).to be_owned_by(nil, nil)
    end
  end
end
