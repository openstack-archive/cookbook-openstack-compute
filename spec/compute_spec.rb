require "spec_helper"

describe "nova::compute" do
  describe "ubuntu" do
    before do
      nova_common_stubs
      @chef_run_opts = ::UBUNTU_OPTS
      @chef_run = ::ChefSpec::ChefRunner.new @chef_run_opts
      @chef_run.converge "nova::compute"
    end

    expect_runs_nova_common_recipe

    it "runs api-metadata recipe" do
      expect(@chef_run).to include_recipe "nova::api-metadata"
    end

    it "runs network recipe" do
      expect(@chef_run).to include_recipe "nova::network"
    end

    it "installs nova compute packages" do
      expect(@chef_run).to upgrade_package "nova-compute"
    end

    it "installs kvm when virt_type is 'kvm'" do
      chef_run = ::ChefSpec::ChefRunner.new @chef_run_opts
      node = chef_run.node
      node.set["nova"]["libvirt"]["virt_type"] = "kvm"
      chef_run.converge "nova::compute"

      expect(chef_run).to upgrade_package "nova-compute-kvm"
      expect(chef_run).not_to upgrade_package "nova-compute-qemu"
    end

    it "installs qemu when virt_type is 'qemu'" do
      chef_run = ::ChefSpec::ChefRunner.new @chef_run_opts
      node = chef_run.node
      node.set["nova"]["libvirt"]["virt_type"] = "qemu"
      chef_run.converge "nova::compute"

      expect(chef_run).to upgrade_package "nova-compute-qemu"
      expect(chef_run).not_to upgrade_package "nova-compute-kvm"
    end

    describe "nova-compute.conf" do
      before do
        @file = @chef_run.cookbook_file "/etc/nova/nova-compute.conf"
      end

      it "has proper modes" do
        expect(sprintf("%o", @file.mode)).to eq "644"
      end

      it "template contents" do
        pending "TODO: implement"
      end
    end

    it "starts nova compute on boot" do
      expect(@chef_run).to set_service_to_start_on_boot "nova-compute"
    end

    it "runs libvirt recipe" do
      expect(@chef_run).to include_recipe "nova::libvirt"
    end
  end
end
