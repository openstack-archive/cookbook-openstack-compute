require "spec_helper"

describe "nova::api-ec2" do
  describe "ubuntu" do
    before do
      nova_common_stubs
      @chef_run = ::ChefSpec::ChefRunner.new(
        :platform  => "ubuntu",
        :version   => "12.04",
        :log_level => ::LOG_LEVEL
      ).converge "nova::api-ec2"
    end

    expect_runs_nova_common_recipe

    expect_creates_nova_lock_dir

    expect_installs_python_keystone

    it "installs ec2 api packages" do
      expect(@chef_run).to upgrade_package "nova-api-ec2"
    end

    it "starts ec2 api on boot" do
      expect(@chef_run).to set_service_to_start_on_boot "nova-api-ec2"
    end

    expect_creates_api_paste

    it "notifies nova-api-ec2 restart" do
      @file = @chef_run.template "/etc/nova/api-paste.ini"
      expect(@file).to notify "service[nova-api-ec2]", :restart
    end
  end
end
