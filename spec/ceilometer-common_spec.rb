require_relative "spec_helper"

describe "openstack-compute::ceilometer-common" do
  before { compute_stubs }
  describe "ubuntu" do
    before do
      @chef_run = ::ChefSpec::ChefRunner.new(::UBUNTU_OPTS) do |n|
        n.set["openstack"]["mq"] = {
          "host" => "127.0.0.1"
        }
        n.set["openstack"]["compute"]["syslog"]["use"] = true
      end
      @node = @chef_run.node
      @chef_run.converge "openstack-compute::ceilometer-common"
    end

    expect_runs_nova_common_recipe

    it "runs pip recipe" do
      expect(@chef_run).to include_recipe "python::pip"
    end

    it "upgrades dependent packages" do
      expect(@chef_run).to upgrade_package 'libxslt-dev'
      expect(@chef_run).to upgrade_package 'libxml2-dev'
    end

    it "removes old ceilometer python package" do
      define_resource_matchers([:remove], [:python_pip], :name)
      expect(@chef_run).to remove_python_pip "ceilometer"
    end

    it "deletes ceilometer binaries" do
      expect(@chef_run).to delete_file "ceilometer-agent-compute"
      expect(@chef_run).to delete_file "ceilometer-agent-central"
      expect(@chef_run).to delete_file "ceilometer-collector"
      expect(@chef_run).to delete_file "ceilometer-dbsync"
      expect(@chef_run).to delete_file "ceilometer-api"
    end

    it "syncs from git" do
      define_resource_matchers([:sync], [:git], :name)
      expect(@chef_run).to sync_git "/opt/ceilometer"
    end

    describe "install_dir" do
      before do
        @directory = @chef_run.directory "/opt/ceilometer"
      end

      it "is owned by root" do
        expect(@directory).to be_owned_by("nova", "nova")
      end

      it "has the right permissions" do
        expect(sprintf("%o", @directory.mode)).to eq("755")
      end
    end

    describe "ceilometer.conf directory" do
      before do
        @directory = @chef_run.directory "/etc/ceilometer"
      end

      it "is owned by compute_owner" do
        expect(@directory).to be_owned_by("nova", "nova")
      end

      it "has the right permissions" do
        expect(sprintf("%o", @directory.mode)).to eq("755")
      end
    end

    describe "ceilometer.conf" do
      before do
        @file = @chef_run.template "/etc/ceilometer/ceilometer.conf"
      end

      it "is owned by the nova" do
        expect(@file).to be_owned_by("nova", "nova")
      end

      it "has 644 permissions" do
        expect(sprintf("%o", @file.mode)).to eq("600")
      end

      it "has rabbit_user" do
        expect(@chef_run).to create_file_with_content @file.name,
          "rabbit_userid = guest"
      end

      it "has rabbit_password" do
        expect(@chef_run).to create_file_with_content @file.name,
          "rabbit_password = rabbit-pass"
      end

      it "has rabbit_port" do
        expect(@chef_run).to create_file_with_content @file.name,
          "rabbit_port = 5672"
      end

      it "has rabbit_host" do
        expect(@chef_run).to create_file_with_content @file.name,
          "rabbit_host = 127.0.0.1"
      end

      it "has rabbit_virtual_host" do
        expect(@chef_run).to create_file_with_content @file.name,
          "rabbit_virtual_host = /"
      end
    end

    describe "policy.json" do
      before do
        @file = @chef_run.cookbook_file "/etc/ceilometer/policy.json"
      end

      it "is owned by nova" do
        expect(@file).to be_owned_by("nova", "nova")
      end

      it "has 755 permissions" do
        expect(sprintf("%o", @file.mode)).to eq("755")
      end
    end
  end
end
