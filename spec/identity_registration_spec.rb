require "spec_helper"

describe "openstack-compute::identity_registration" do
  before do
    @identity_register_mock = double "identity_register"
  end

  it "registers service tenant" do
    compute_stubs
    ::Chef::Recipe.any_instance.stub(:openstack_identity_register)
    ::Chef::Recipe.any_instance.should_receive(:openstack_identity_register).
      with("Register Service Tenant") do |&arg|
        @identity_register_mock.should_receive(:auth_uri).
          with "https://127.0.0.1:35357/v2.0"
        @identity_register_mock.should_receive(:bootstrap_token).
          with "bootstrap-token"
        @identity_register_mock.should_receive(:tenant_name).
          with "service"
        @identity_register_mock.should_receive(:tenant_description).
          with "Service Tenant"
        @identity_register_mock.should_receive(:action).
          with :create_tenant

        @identity_register_mock.instance_eval &arg
    end

    chef_run = ::ChefSpec::ChefRunner.new ::UBUNTU_OPTS
    chef_run.converge "openstack-compute::identity_registration"
  end

  it "registers service user" do
    compute_stubs
    ::Chef::Recipe.any_instance.stub(:openstack_identity_register)
    ::Chef::Recipe.any_instance.should_receive(:openstack_identity_register).
      with("Register Service User") do |&arg|
        @identity_register_mock.should_receive(:auth_uri).
          with "https://127.0.0.1:35357/v2.0"
        @identity_register_mock.should_receive(:bootstrap_token).
          with "bootstrap-token"
        @identity_register_mock.should_receive(:tenant_name).
          with "service"
        @identity_register_mock.should_receive(:user_name).
          with "nova"
        @identity_register_mock.should_receive(:user_pass).
          with "nova-pass"
        @identity_register_mock.should_receive(:action).
          with :create_user

        @identity_register_mock.instance_eval &arg
    end

    chef_run = ::ChefSpec::ChefRunner.new ::UBUNTU_OPTS
    chef_run.converge "openstack-compute::identity_registration"
  end

  it "grants admin role to service user for service tenant" do
    compute_stubs
    ::Chef::Recipe.any_instance.stub(:openstack_identity_register)
    ::Chef::Recipe.any_instance.should_receive(:openstack_identity_register).
      with("Grant 'admin' Role to Service User for Service Tenant") do |&arg|
        @identity_register_mock.should_receive(:auth_uri).
          with "https://127.0.0.1:35357/v2.0"
        @identity_register_mock.should_receive(:bootstrap_token).
          with "bootstrap-token"
        @identity_register_mock.should_receive(:tenant_name).
          with "service"
        @identity_register_mock.should_receive(:user_name).
          with "nova"
        @identity_register_mock.should_receive(:role_name).
          with "admin"
        @identity_register_mock.should_receive(:action).
          with :grant_role

        @identity_register_mock.instance_eval &arg
    end

    chef_run = ::ChefSpec::ChefRunner.new ::UBUNTU_OPTS
    chef_run.converge "openstack-compute::identity_registration"
  end

  it "registers compute service" do
    compute_stubs
    ::Chef::Recipe.any_instance.stub(:openstack_identity_register)
    ::Chef::Recipe.any_instance.should_receive(:openstack_identity_register).
      with("Register Compute Service") do |&arg|
        @identity_register_mock.should_receive(:auth_uri).
          with "https://127.0.0.1:35357/v2.0"
        @identity_register_mock.should_receive(:bootstrap_token).
          with "bootstrap-token"
        @identity_register_mock.should_receive(:service_name).
          with "nova"
        @identity_register_mock.should_receive(:service_type).
          with "compute"
        @identity_register_mock.should_receive(:service_description).
          with "Nova Compute Service"
        @identity_register_mock.should_receive(:action).
          with :create_service

        @identity_register_mock.instance_eval &arg
    end

    chef_run = ::ChefSpec::ChefRunner.new ::UBUNTU_OPTS
    chef_run.converge "openstack-compute::identity_registration"
  end

  it "registers compute endpoint" do
    compute_stubs
    ::Chef::Recipe.any_instance.stub(:openstack_identity_register)
    ::Chef::Recipe.any_instance.should_receive(:openstack_identity_register).
      with("Register Compute Endpoint") do |&arg|
        @identity_register_mock.should_receive(:auth_uri).
          with "https://127.0.0.1:35357/v2.0"
        @identity_register_mock.should_receive(:bootstrap_token).
          with "bootstrap-token"
        @identity_register_mock.should_receive(:service_type).
          with "compute"
        @identity_register_mock.should_receive(:endpoint_region).
          with "RegionOne"
        @identity_register_mock.should_receive(:endpoint_adminurl).
          with "https://127.0.0.1:8774/v2/%(tenant_id)s"
        @identity_register_mock.should_receive(:endpoint_internalurl).
          with "https://127.0.0.1:8774/v2/%(tenant_id)s"
        @identity_register_mock.should_receive(:endpoint_publicurl).
          with "https://127.0.0.1:8774/v2/%(tenant_id)s"
        @identity_register_mock.should_receive(:action).
          with :create_endpoint

        @identity_register_mock.instance_eval &arg
    end

    chef_run = ::ChefSpec::ChefRunner.new ::UBUNTU_OPTS
    chef_run.converge "openstack-compute::identity_registration"
  end

  it "registers metering service" do
    compute_stubs
    ::Chef::Recipe.any_instance.stub(:openstack_identity_register)
    ::Chef::Recipe.any_instance.should_receive(:openstack_identity_register).
      with("Register Metering Service") do |&arg|
        @identity_register_mock.should_receive(:auth_uri).
          with "https://127.0.0.1:35357/v2.0"
        @identity_register_mock.should_receive(:bootstrap_token).
          with "bootstrap-token"
        @identity_register_mock.should_receive(:service_name).
          with "ceilometer"
        @identity_register_mock.should_receive(:service_type).
          with "metering"
        @identity_register_mock.should_receive(:service_description).
          with "Ceilometer Service"
        @identity_register_mock.should_receive(:action).
          with :create_service

        @identity_register_mock.instance_eval &arg
    end

    chef_run = ::ChefSpec::ChefRunner.new ::UBUNTU_OPTS
    chef_run.converge "openstack-compute::identity_registration"
  end

  it "registers metering endpoint" do
    compute_stubs
    ::Chef::Recipe.any_instance.stub(:openstack_identity_register)
    ::Chef::Recipe.any_instance.should_receive(:openstack_identity_register).
      with("Register Metering Endpoint") do |&arg|
        @identity_register_mock.should_receive(:auth_uri).
          with "https://127.0.0.1:35357/v2.0"
        @identity_register_mock.should_receive(:bootstrap_token).
          with "bootstrap-token"
        @identity_register_mock.should_receive(:service_type).
          with "metering"
        @identity_register_mock.should_receive(:endpoint_region).
          with "RegionOne"
        @identity_register_mock.should_receive(:endpoint_adminurl).
          with "https://127.0.0.1:8777/v1"
        @identity_register_mock.should_receive(:endpoint_internalurl).
          with "https://127.0.0.1:8777/v1"
        @identity_register_mock.should_receive(:endpoint_publicurl).
          with "https://127.0.0.1:8777/v1"
        @identity_register_mock.should_receive(:action).
          with :create_endpoint

        @identity_register_mock.instance_eval &arg
    end

    chef_run = ::ChefSpec::ChefRunner.new ::UBUNTU_OPTS
    chef_run.converge "openstack-compute::identity_registration"
  end

  it "registers ec2 service" do
    compute_stubs
    ::Chef::Recipe.any_instance.stub(:openstack_identity_register)
    ::Chef::Recipe.any_instance.should_receive(:openstack_identity_register).
      with("Register EC2 Service") do |&arg|
        @identity_register_mock.should_receive(:auth_uri).
          with "https://127.0.0.1:35357/v2.0"
        @identity_register_mock.should_receive(:bootstrap_token).
          with "bootstrap-token"
        @identity_register_mock.should_receive(:service_name).
          with "ec2"
        @identity_register_mock.should_receive(:service_type).
          with "ec2"
        @identity_register_mock.should_receive(:service_description).
          with "EC2 Compatibility Layer"
        @identity_register_mock.should_receive(:action).
          with :create_service

        @identity_register_mock.instance_eval &arg
    end

    chef_run = ::ChefSpec::ChefRunner.new ::UBUNTU_OPTS
    chef_run.converge "openstack-compute::identity_registration"
  end

  it "registers compute endpoint" do
    compute_stubs
    ::Chef::Recipe.any_instance.stub(:openstack_identity_register)
    ::Chef::Recipe.any_instance.should_receive(:openstack_identity_register).
      with("Register EC2 Endpoint") do |&arg|
        @identity_register_mock.should_receive(:auth_uri).
          with "https://127.0.0.1:35357/v2.0"
        @identity_register_mock.should_receive(:bootstrap_token).
          with "bootstrap-token"
        @identity_register_mock.should_receive(:service_type).
          with "ec2"
        @identity_register_mock.should_receive(:endpoint_region).
          with "RegionOne"
        @identity_register_mock.should_receive(:endpoint_adminurl).
          with "https://127.0.0.1:8773/services/Admin"
        @identity_register_mock.should_receive(:endpoint_internalurl).
          with "https://127.0.0.1:8773/services/Cloud"
        @identity_register_mock.should_receive(:endpoint_publicurl).
          with "https://127.0.0.1:8773/services/Cloud"
        @identity_register_mock.should_receive(:action).
          with :create_endpoint

        @identity_register_mock.instance_eval &arg
    end

    chef_run = ::ChefSpec::ChefRunner.new ::UBUNTU_OPTS
    chef_run.converge "openstack-compute::identity_registration"
  end
end
