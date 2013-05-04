require "chefspec"

::LOG_LEVEL = :fatal

def nova_common_stubs
  ::Chef::Recipe.any_instance.stub(:config_by_role).
    with("rabbitmq-server", "queue").and_return(
      {'host' => 'rabbit-host', 'port' => 'rabbit-port'}
    )
  ::Chef::Recipe.any_instance.stub(:config_by_role).
    with("keystone", "keystone").and_return(
      {'admin_tenant_name' => 'admin-tenant', 'admin_user' => 'admin-user'}
    )
  ::Chef::Recipe.any_instance.stub(:db_password).and_return []
  ::Chef::Recipe.any_instance.stub(:user_password).and_return []
  ::Chef::Recipe.any_instance.stub(:service_password).and_return []
  ::Chef::Recipe.any_instance.stub(:memcached_servers).and_return []
end

def expect_runs_nova_common_recipe
  it "installs nova-common" do
    expect(@chef_run).to include_recipe "nova::nova-common"
  end
end

def expect_installs_python_keystone
  it "installs python-keystone" do
    expect(@chef_run).to upgrade_package "python-keystone"
  end
end

def expect_creates_nova_lock_dir
  describe "/var/lock/nova" do
    before do
      @dir = @chef_run.directory "/var/lock/nova"
    end

    it "has proper owner" do
      expect(@dir).to be_owned_by "nova", "nova"
    end

    it "has proper modes" do
      expect(sprintf("%o", @dir.mode)).to eq "700"
    end
  end
end

def expect_creates_api_paste
  describe "api-paste.ini" do
    before do
      @file = @chef_run.template "/etc/nova/api-paste.ini"
    end

    it "has proper owner" do
      expect(@file).to be_owned_by "nova", "nova"
    end

    it "has proper modes" do
      expect(sprintf("%o", @file.mode)).to eq "644"
    end

    it "template contents" do
      pending "TODO: implement"
    end
  end
end
