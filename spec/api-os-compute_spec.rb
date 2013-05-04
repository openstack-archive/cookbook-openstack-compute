require "spec_helper"

describe "nova::api-os-compute" do
  describe "ubuntu" do
    before do
      nova_common_stubs
      @chef_run = ::ChefSpec::ChefRunner.new(
        :platform  => "ubuntu",
        :version   => "12.04",
        :log_level => ::LOG_LEVEL
      ).converge "nova::api-os-compute"
    end

    expect_runs_nova_common_recipe

    expect_creates_nova_lock_dir

    describe "/var/cache/nova/api" do
      before do
        @dir = @chef_run.directory "/var/cache/nova"
      end

      ##
      #TODO: ChefSpec needs to handle guards better.  This
      #      should only be created when pki is enabled.
      it "has proper owner" do
        expect(@dir).to be_owned_by "nova", "nova"
      end

      it "has proper modes" do
        expect(sprintf("%o", @dir.mode)).to eq "700"
      end
    end

    expect_installs_python_keystone

    it "installs openstack api packages" do
      expect(@chef_run).to upgrade_package "nova-api-os-compute"
    end

    it "starts openstack api on boot" do
      expect(@chef_run).to set_service_to_start_on_boot "nova-api-os-compute"
    end

    expect_creates_api_paste

    it "notifies nova-api-os-compute restart" do
      @file = @chef_run.template "/etc/nova/api-paste.ini"
      expect(@file).to notify "service[nova-api-os-compute]", :restart
    end
  end
end
