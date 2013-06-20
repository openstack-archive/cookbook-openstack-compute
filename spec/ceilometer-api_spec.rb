require_relative "spec_helper"

describe "openstack-compute::ceilometer-api" do
  describe "ubuntu" do
    before do
      compute_stubs
      @chef_run = ::ChefSpec::ChefRunner.new ::UBUNTU_OPTS
      @chef_run.converge "openstack-compute::ceilometer-api"
    end

    expect_runs_ceilometer_common_recipe

    it "starts apache2 service" do
      expect(@chef_run).to start_service("apache2")
    end

    it "starts ceilometer-api service" do
      expect(@chef_run).to start_service("ceilometer-api")
    end

    it "includes apache2 default recipe" do
      expect(@chef_run).to include_recipe "apache2"
    end

    it "includes apache2 mod_proxy recipe" do
      expect(@chef_run).to include_recipe "apache2::mod_proxy"
    end

    it "includes apache2 mod_proxy_http recipe" do
      expect(@chef_run).to include_recipe "apache2::mod_proxy_http"
    end

    describe "/etc/apache2/sites-available/meter" do
      before do
        @file = @chef_run.template "/etc/apache2/sites-available/meter"
      end

      it "has proper owner" do
        expect(@file).to be_owned_by "root", "root"
      end

      it "template contents" do
        pending "TODO: implement"
      end
    end

    describe "/etc/apache2/htpasswd" do
      before do
        @file = @chef_run.file "/etc/apache2/htpasswd"
      end

      it "has proper owner" do
        expect(@file).to be_owned_by "root", "root"
      end

      it "has proper modes" do
        expect(sprintf("%o", @file.mode)).to eq "755"
      end
    end
  end
end
