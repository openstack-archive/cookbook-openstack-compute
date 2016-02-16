# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-compute::identity_registration' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'compute_stubs'

    it 'registers service tenant' do
      expect(chef_run).to create_tenant_openstack_identity_register(
        'Register Service Tenant'
      ).with(
        auth_uri: 'http://127.0.0.1:35357/v2.0',
        bootstrap_token: 'bootstrap-token',
        tenant_name: 'service',
        tenant_description: 'Service Tenant'
      )
    end

    it 'registers service user' do
      expect(chef_run).to create_user_openstack_identity_register(
        'Register Service User'
      ).with(
        auth_uri: 'http://127.0.0.1:35357/v2.0',
        bootstrap_token: 'bootstrap-token',
        tenant_name: 'service',
        user_name: 'nova',
        user_pass: 'nova-pass'
      )
    end

    it 'grants admin role to service user for service tenant' do
      expect(chef_run).to grant_role_openstack_identity_register(
        "Grant 'admin' Role to Service User for Service Tenant"
      ).with(
        auth_uri: 'http://127.0.0.1:35357/v2.0',
        bootstrap_token: 'bootstrap-token',
        tenant_name: 'service',
        user_name: 'nova',
        role_name: 'admin'
      )
    end

    it 'registers compute service' do
      expect(chef_run).to create_service_openstack_identity_register(
        'Register Compute Service'
      ).with(
        auth_uri: 'http://127.0.0.1:35357/v2.0',
        bootstrap_token: 'bootstrap-token',
        service_name: 'nova',
        service_type: 'compute',
        service_description: 'Nova Compute Service'
      )
    end

    context 'registers compute endpoint' do
      it 'with default values' do
        expect(chef_run).to create_endpoint_openstack_identity_register(
          'Register Compute Endpoint'
        ).with(
          auth_uri: 'http://127.0.0.1:35357/v2.0',
          bootstrap_token: 'bootstrap-token',
          service_type: 'compute',
          endpoint_region: 'RegionOne',
          endpoint_adminurl: 'http://127.0.0.1:8774/v2/%(tenant_id)s',
          endpoint_internalurl: 'http://127.0.0.1:8774/v2/%(tenant_id)s',
          endpoint_publicurl: 'http://127.0.0.1:8774/v2/%(tenant_id)s'
        )
      end

      it 'register endpoint with all different URLs' do
        public_url = 'https://public.host:789/public_path'
        internal_url = 'http://internal.host:456/internal_path'
        admin_url = 'https://admin.host:123/admin_path'
        node.set['openstack']['endpoints']['public']['compute-api']['uri'] = public_url
        node.set['openstack']['endpoints']['internal']['compute-api']['uri'] = internal_url
        node.set['openstack']['endpoints']['admin']['compute-api']['uri'] = admin_url

        expect(chef_run).to create_endpoint_openstack_identity_register(
          'Register Compute Endpoint'
        ).with(
          endpoint_adminurl: admin_url,
          endpoint_internalurl: internal_url,
          endpoint_publicurl: public_url
        )
      end

      it 'with custom region override' do
        node.set['openstack']['region'] = 'computeRegion'
        expect(chef_run).to create_endpoint_openstack_identity_register(
          'Register Compute Endpoint'
        ).with(endpoint_region: 'computeRegion')
      end
    end

    it 'registers ec2 service' do
      expect(chef_run).to create_service_openstack_identity_register(
        'Register EC2 Service'
      ).with(
        auth_uri: 'http://127.0.0.1:35357/v2.0',
        bootstrap_token: 'bootstrap-token',
        service_name: 'ec2',
        service_type: 'ec2',
        service_description: 'EC2 Compatibility Layer'
      )
    end

    context 'registers ec2 endpoint' do
      it 'with default values' do
        expect(chef_run).to create_endpoint_openstack_identity_register(
          'Register EC2 Endpoint'
        ).with(
          auth_uri: 'http://127.0.0.1:35357/v2.0',
          bootstrap_token: 'bootstrap-token',
          service_type: 'ec2',
          endpoint_region: 'RegionOne',
          endpoint_adminurl: 'http://127.0.0.1:8773/services/Admin',
          endpoint_internalurl: 'http://127.0.0.1:8773/services/Cloud',
          endpoint_publicurl: 'http://127.0.0.1:8773/services/Cloud'
        )
      end

      it 'with different URLs for all endpoints' do
        admin_url = 'https://admin.host:123/admin_path'
        public_url = 'https://public.host:789/public_path'
        internal_url = 'http://internal.host:456/internal_path'

        node.set['openstack']['endpoints']['admin']['compute-ec2']['uri'] = admin_url
        node.set['openstack']['endpoints']['internal']['compute-ec2-api']['uri'] = internal_url
        node.set['openstack']['endpoints']['public']['compute-ec2-api']['uri'] = public_url
        expect(chef_run).to create_endpoint_openstack_identity_register(
          'Register EC2 Endpoint'
        ).with(
          auth_uri: 'http://127.0.0.1:35357/v2.0',
          bootstrap_token: 'bootstrap-token',
          service_type: 'ec2',
          endpoint_region: 'RegionOne',
          endpoint_adminurl: admin_url,
          endpoint_internalurl: internal_url,
          endpoint_publicurl: public_url
        )
      end

      it 'with customer region override' do
        node.set['openstack']['region'] = 'ec2Region'
        expect(chef_run).to create_endpoint_openstack_identity_register(
          'Register EC2 Endpoint'
        ).with(endpoint_region: 'ec2Region')
      end
    end

    describe "when 'ec2' is not in the list of enabled_apis" do
      before do
        node.set['openstack']['compute']['conf']['DEFAULT']['enabled_apis'] = 'osapi_compute'
      end

      it 'does not register ec2 service' do
        expect(chef_run).not_to create_service_openstack_identity_register(
          'Register EC2 Service'
        )
      end

      it 'does not register ec2 endpoint' do
        expect(chef_run).not_to create_endpoint_openstack_identity_register(
          'Register EC2 Endpoint'
        )
      end
    end
  end
end
