require_relative "spec_helper"

describe "openstack-compute::nova-common" do
  describe "ubuntu" do
    before do
      compute_stubs
      @chef_run = ::ChefSpec::ChefRunner.new ::UBUNTU_OPTS
      @node = @chef_run.node
      @node.set["openstack"]["compute"]["syslog"]["use"] = true
      @chef_run.converge "openstack-compute::nova-common"
    end

    it "doesn't run epel recipe" do
      expect(@chef_run).to_not include_recipe 'yum::epel'
    end

    it "runs logging recipe if node attributes say to" do
      expect(@chef_run).to include_recipe "openstack-common::logging"
    end

    it "doesn't run logging recipe" do
      chef_run = ::ChefSpec::ChefRunner.new ::UBUNTU_OPTS
      chef_run.converge "openstack-compute::nova-common"

      expect(chef_run).not_to include_recipe "openstack-common::logging"
    end

    it "installs nova common packages" do
      expect(@chef_run).to upgrade_package "nova-common"
    end

    it "installs memcache python packages" do
      expect(@chef_run).to install_package "python-memcache"
    end

    describe "/etc/nova" do
      before do
        @dir = @chef_run.directory "/etc/nova"
      end

      it "has proper owner" do
        expect(@dir).to be_owned_by "nova", "nova"
      end

      it "has proper modes" do
        expect(sprintf("%o", @dir.mode)).to eq "700"
      end
    end

    describe "/etc/nova/rootwrap.d" do
      before do
        @dir = @chef_run.directory "/etc/nova/rootwrap.d"
      end

      it "has proper owner" do
        expect(@dir).to be_owned_by "root", "root"
      end

      it "has proper modes" do
        expect(sprintf("%o", @dir.mode)).to eq "700"
      end
    end

    describe "nova.conf" do
      before do
        @file = @chef_run.template "/etc/nova/nova.conf"
        # README(shep) need this to evaluate nova.conf.erb template
        @chef_run.node.set['cpu'] = Hash.new()
        @chef_run.node.set.cpu.total = "2"
      end

      it "has proper owner" do
        expect(@file).to be_owned_by "nova", "nova"
      end

      it "has proper modes" do
        expect(sprintf("%o", @file.mode)).to eq "644"
      end

      it "has correct force_dhcp_release value" do
        expect(@chef_run).to create_file_with_content "/etc/nova/nova.conf",
          "force_dhcp_release=true"
      end

      it "has virtio enabled" do
        expect(@chef_run).to create_file_with_content "/etc/nova/nova.conf",
          "libvirt_use_virtio_for_bridges=true"
      end

      it "does not have ec2_private_dns_show_ip option" do
        expect(@chef_run).to_not create_file_with_content "/etc/nova/nova.conf",
          "ec2_private_dns_show_ip"
      end
    end

    describe "rootwrap.conf" do
      before do
        @file = @chef_run.template "/etc/nova/rootwrap.conf"
      end

      it "has proper owner" do
        expect(@file).to be_owned_by "root", "root"
      end

      it "has proper modes" do
        expect(sprintf("%o", @file.mode)).to eq "644"
      end

      it "template contents" do
        pending "TODO: implement"
      end
    end

    describe "api-metadata.filters" do
      before do
        @file = @chef_run.template "/etc/nova/rootwrap.d/api-metadata.filters"
      end

      it "has proper owner" do
        expect(@file).to be_owned_by "root", "root"
      end

      it "has proper modes" do
        expect(sprintf("%o", @file.mode)).to eq "644"
      end

      it "template contents" do
        pending "TODO: implement"
      end
    end

    describe "compute.filters" do
      before do
        @file = @chef_run.template "/etc/nova/rootwrap.d/compute.filters"
      end

      it "has proper owner" do
        expect(@file).to be_owned_by "root", "root"
      end

      it "has proper modes" do
        expect(sprintf("%o", @file.mode)).to eq "644"
      end

      it "template contents" do
        pending "TODO: implement"
      end
    end

    describe "network.filters" do
      before do
        @file = @chef_run.template "/etc/nova/rootwrap.d/network.filters"
      end

      it "has proper owner" do
        expect(@file).to be_owned_by "root", "root"
      end

      it "has proper modes" do
        expect(sprintf("%o", @file.mode)).to eq "644"
      end

      it "template contents" do
        pending "TODO: implement"
      end
    end

    describe "openrc" do
      before do
        @file = @chef_run.template "/root/openrc"
      end

      it "has proper owner" do
        expect(@file).to be_owned_by "root", "root"
      end

      it "has proper modes" do
        expect(sprintf("%o", @file.mode)).to eq "600"
      end

      it "template contents" do
        pending "TODO: implement"
      end
    end

    it "enables nova login" do
      cmd = "usermod -s /bin/sh nova"
      expect(@chef_run).to execute_command cmd
    end
  end
end
