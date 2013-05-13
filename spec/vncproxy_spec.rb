require "spec_helper"

describe "nova::vncproxy" do
  describe "ubuntu" do
    before do
      nova_common_stubs
      @chef_run = ::ChefSpec::ChefRunner.new ::UBUNTU_OPTS
      @chef_run.converge "nova::vncproxy"
    end

    expect_runs_nova_common_recipe

    it "installs vncproxy packages" do
      expect(@chef_run).to upgrade_package "novnc"
      expect(@chef_run).to upgrade_package "websockify"
      expect(@chef_run).to upgrade_package "nova-novncproxy"
    end

    it "installs consoleauth packages" do
      expect(@chef_run).to upgrade_package "nova-consoleauth"
    end

    describe "patches" do
      describe "vnc_auto.html" do
        before do
          @file = @chef_run.cookbook_file "/usr/share/novnc/vnc_auto.html"
        end

        it "has proper owner" do
          expect(@file).to be_owned_by "root", "root"
        end

        it "has proper modes" do
          expect(sprintf("%o", @file.mode)).to eq "644"
        end

        it "doesn't create file when apply_novnc_patch false" do
          chef_run = ::ChefSpec::ChefRunner.new ::UBUNTU_OPTS
          node = chef_run.node
          node.set["nova"]["apply_novnc_patch"] = false
          chef_run.converge "nova::vncproxy"

          expect(chef_run).not_to create_cookbook_file @file.name
        end
      end

      describe "ui.js" do
        before do
          @file = @chef_run.cookbook_file "/usr/share/novnc/include/ui.js"
        end

        it "has proper owner" do
          expect(@file).to be_owned_by "root", "root"
        end

        it "has proper modes" do
          expect(sprintf("%o", @file.mode)).to eq "644"
        end

        it "doesn't create file when apply_novnc_patch false" do
          chef_run = ::ChefSpec::ChefRunner.new ::UBUNTU_OPTS
          node = chef_run.node
          node.set["nova"]["apply_novnc_patch"] = false
          chef_run.converge "nova::vncproxy"

          expect(chef_run).not_to create_cookbook_file @file.name
        end
      end

      it "starts nova vncproxy on boot" do
        expect(@chef_run).to set_service_to_start_on_boot "nova-novncproxy"
      end

      it "starts nova consoleauth" do
        expect(@chef_run).to start_service "nova-consoleauth"
      end

      it "starts nova consoleauth on boot" do
        expect(@chef_run).to set_service_to_start_on_boot "nova-consoleauth"
      end
    end
  end
end
