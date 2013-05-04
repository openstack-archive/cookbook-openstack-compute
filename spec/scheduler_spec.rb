require "spec_helper"

describe "nova::scheduler" do
  describe "ubuntu" do
    before do
      nova_common_stubs
      @chef_run_opts = {
        :platform  => "ubuntu",
        :version   => "12.04",
        :log_level => ::LOG_LEVEL,
      }
      @chef_run = ::ChefSpec::ChefRunner.new @chef_run_opts
      @chef_run.converge "nova::scheduler"
    end

    expect_runs_nova_common_recipe

    expect_creates_nova_lock_dir

    it "installs nova scheduler packages" do
      expect(@chef_run).to upgrade_package "nova-scheduler"
    end

    it "starts nova scheduler" do
      expect(@chef_run).to start_service "nova-scheduler"
    end

    it "starts nova scheduler on boot" do
      expect(@chef_run).to set_service_to_start_on_boot "nova-scheduler"
    end
  end
end
