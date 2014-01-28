require_relative "spec_helper"

describe "openstack-compute::nova-common" do
  before { compute_stubs }
  describe "redhat" do
    before do
      @chef_run = ::ChefSpec::Runner.new ::REDHAT_OPTS
      @chef_run.converge "openstack-compute::nova-common"
    end

    it "runs epel recipe" do
      expect(@chef_run).to include_recipe "yum::epel"
    end

    it "installs nova common packages" do
      expect(@chef_run).to upgrade_package "openstack-nova-common"
    end

    it "installs mysql python packages by default" do
      expect(@chef_run).to install_package "MySQL-python"
    end

    it "installs db2 python packages if explicitly told" do
      chef_run = ::ChefSpec::Runner.new ::REDHAT_OPTS
      node = chef_run.node
      node.set["openstack"]["db"]["compute"]["service_type"] = "db2"
      chef_run.converge "openstack-compute::nova-common"

      ["db2-odbc", "python-ibm-db", "python-ibm-db-sa"].each do |pkg|
        expect(chef_run).to install_package pkg
      end
    end

    it "installs memcache python packages" do
      expect(@chef_run).to install_package "python-memcached"
    end

    describe "nova.conf" do
      before do
        @filename = "/etc/nova/nova.conf"
        # README(shep) need this to evaluate nova.conf.erb template
        @chef_run.node.set['cpu'] = Hash.new()
        @chef_run.node.set.cpu.total = "2"
      end

      [/^ec2_private_dns_show_ip=True$/, /^force_dhcp_release=false$/].each do |content|
        it "has a \"#{content.source[1...-1]}\" line" do
          expect(@chef_run).to render_file(@filename).with_content(content)
        end
      end
    end
  end
end
