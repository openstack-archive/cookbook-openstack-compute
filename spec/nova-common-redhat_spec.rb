require "spec_helper"

describe "openstack-compute::nova-common" do
  describe "redhat" do
    before do
      nova_common_stubs
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

    describe "nova.conf" do
      before do
        @file = @chef_run.template "/etc/nova/nova.conf"
	# README(shep) need this to evaluate nova.conf.erb template
	@chef_run.node['cpu'] = Hash.new()
	@chef_run.node.cpu.total = "2"
      end

      it "has correct force_dhcp_release value" do
        expect(@chef_run).to create_file_with_content "/etc/nova/nova.conf",
	  "force_dhcp_release=false"
      end

      it "has ec2_private_dns_show_ip enabled" do
        expect(@chef_run).to create_file_with_content "/etc/nova/nova.conf",
	  "ec2_private_dns_show_ip=True"
      end
    end
  end
end
