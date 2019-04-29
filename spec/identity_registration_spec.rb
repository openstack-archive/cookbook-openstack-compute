# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-compute::identity_registration' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'compute_stubs'

    connection_params = {
      openstack_auth_url: 'http://127.0.0.1:5000/v3/auth/tokens',
      openstack_username: 'admin',
      openstack_api_key: 'admin',
      openstack_project_name: 'admin',
      openstack_domain_name: 'default',
      openstack_endpoint_type: 'internalURL',
    }
    service_name = 'nova'
    service_type = 'compute'
    service_user = 'nova'
    url = 'http://127.0.0.1:8774/v2.1/%(tenant_id)s'
    region = 'RegionOne'
    project_name = 'service'
    role_name = 'admin'
    password = 'nova-pass'
    domain_name = 'Default'
    placement_service_name = 'nova-placement'
    placement_service_type = 'placement'
    placement_service_user = 'placement'
    placement_password = 'placement-pass'
    placement_url = 'http://127.0.0.1:8778'

    it "registers #{project_name} Project" do
      expect(chef_run).to create_openstack_project(
        project_name
      ).with(
        connection_params: connection_params
      )
    end

    it "registers #{service_name} service" do
      expect(chef_run).to create_openstack_service(
        service_name
      ).with(
        connection_params: connection_params,
        type: service_type
      )
    end

    it 'registers placement service' do
      expect(chef_run).to create_openstack_service(
        placement_service_name
      ).with(
        connection_params: connection_params,
        type: placement_service_type
      )
    end

    context "registers #{service_name} endpoint" do
      %w(internal public).each do |interface|
        it "creates #{interface} endpoint with default values" do
          expect(chef_run).to create_openstack_endpoint(
            service_type
          ).with(
            service_name: service_name,
            # interface: interface,
            url: url,
            region: region,
            connection_params: connection_params
          )
        end
      end
    end

    context 'registers placement endpoint' do
      %w(internal public).each do |interface|
        it "creates #{interface} endpoint with default values" do
          expect(chef_run).to create_openstack_endpoint(
            placement_service_type
          ).with(
            service_name: placement_service_name,
            # interface: interface,
            url: placement_url,
            region: region,
            connection_params: connection_params
          )
        end
      end
    end

    it 'registers nova service user' do
      expect(chef_run).to create_openstack_user(
        service_user
      ).with(
        project_name: project_name,
        password: password,
        connection_params: connection_params
      )
    end

    it 'registers placement service user' do
      expect(chef_run).to create_openstack_user(
        placement_service_user
      ).with(
        domain_name: domain_name,
        project_name: project_name,
        password: placement_password,
        connection_params: connection_params
      )
    end

    context 'grants user roles' do
      [service_user, placement_service_user].each do |user_name|
        it do
          expect(chef_run).to grant_role_openstack_user(
            user_name
          ).with(
            project_name: project_name,
            role_name: role_name,
            connection_params: connection_params
          )
        end
      end
    end
  end
end
