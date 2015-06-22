# encoding: UTF-8
#
# Cookbook Name:: openstack-compute
# Recipe:: identity_registration
#
# Copyright 2013, AT&T
# Copyright 2013, IBM Corp.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'uri'

class ::Chef::Recipe # rubocop:disable Documentation
  include ::Openstack
end

identity_admin_endpoint = admin_endpoint 'identity-admin'
bootstrap_token = get_password 'token', 'openstack_identity_bootstrap_token'
auth_uri = ::URI.decode identity_admin_endpoint.to_s
service_pass = get_password 'service', 'openstack-compute'
service_user = node['openstack']['compute']['service_user']
service_role = node['openstack']['compute']['service_role']
service_tenant_name = node['openstack']['compute']['service_tenant_name']
public_nova_api_endpoint = public_endpoint 'compute-api'
admin_nova_api_endpoint = admin_endpoint 'compute-api'
internal_nova_api_endpoint = internal_endpoint 'compute-api'
# TBD, another clean up opportunity. We could use the 'admin', and
# 'internal' endpoints for a single service name. For now, we'll
# leave the old names in place.
ec2_admin_endpoint = admin_endpoint 'compute-ec2-admin'
ec2_public_endpoint = public_endpoint 'compute-ec2-api'
ec2_internal_endpoint = internal_endpoint 'compute-ec2-api'
region = node['openstack']['compute']['region']

# Register Service Tenant
openstack_identity_register 'Register Service Tenant' do
  auth_uri auth_uri
  bootstrap_token bootstrap_token
  tenant_name service_tenant_name
  tenant_description 'Service Tenant'

  action :create_tenant
end

# Register Service User
openstack_identity_register 'Register Service User' do
  auth_uri auth_uri
  bootstrap_token bootstrap_token
  tenant_name service_tenant_name
  user_name service_user
  user_pass service_pass

  action :create_user
end

## Grant Admin role to Service User for Service Tenant ##
openstack_identity_register "Grant 'admin' Role to Service User for Service Tenant" do
  auth_uri auth_uri
  bootstrap_token bootstrap_token
  tenant_name service_tenant_name
  user_name service_user
  role_name service_role

  action :grant_role
end

# Register Compute Service
openstack_identity_register 'Register Compute Service' do
  auth_uri auth_uri
  bootstrap_token bootstrap_token
  service_name 'nova'
  service_type 'compute'
  service_description 'Nova Compute Service'

  action :create_service
end

# Register Compute Endpoint
openstack_identity_register 'Register Compute Endpoint' do
  auth_uri auth_uri
  bootstrap_token bootstrap_token
  service_type 'compute'
  endpoint_region region
  endpoint_adminurl ::URI.decode admin_nova_api_endpoint.to_s
  endpoint_internalurl ::URI.decode internal_nova_api_endpoint.to_s
  endpoint_publicurl ::URI.decode public_nova_api_endpoint.to_s

  action :create_endpoint
end

if node['openstack']['compute']['enabled_apis'].include?('ec2')
  # Register EC2 Service
  openstack_identity_register 'Register EC2 Service' do
    auth_uri auth_uri
    bootstrap_token bootstrap_token
    service_name 'ec2'
    service_type 'ec2'
    service_description 'EC2 Compatibility Layer'

    action :create_service
  end

  # Register EC2 Endpoint
  openstack_identity_register 'Register EC2 Endpoint' do
    auth_uri auth_uri
    bootstrap_token bootstrap_token
    service_type 'ec2'
    endpoint_region region
    endpoint_adminurl ::URI.decode ec2_admin_endpoint.to_s
    endpoint_internalurl ::URI.decode ec2_internal_endpoint.to_s
    endpoint_publicurl ::URI.decode ec2_public_endpoint.to_s

    action :create_endpoint
  end
end
