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

class ::Chef::Recipe
  include ::Openstack
end

identity_admin_endpoint = admin_endpoint 'identity'
interfaces = {
  public: { url: public_endpoint('compute-api') },
  internal: { url: internal_endpoint('compute-api') },
  admin: { url: admin_endpoint('compute-api') }
}
auth_url = ::URI.decode identity_admin_endpoint.to_s
service_pass = get_password 'service', 'openstack-compute'
service_user = node['openstack']['compute']['conf']['keystone_authtoken']['username']
service_role = node['openstack']['compute']['service_role']
service_project_name = node['openstack']['compute']['conf']['keystone_authtoken']['project_name']
service_domain_name = node['openstack']['compute']['conf']['keystone_authtoken']['user_domain_name']

# TBD, another clean up opportunity. We could use the 'admin', and
# 'internal' endpoints for a single service name. For now, we'll
# leave the old names in place.
region = node['openstack']['region']
admin_user = node['openstack']['identity']['admin_user']
admin_pass = get_password 'user', node['openstack']['identity']['admin_user']
admin_project = node['openstack']['identity']['admin_project']
admin_domain = node['openstack']['identity']['admin_domain_name']

connection_params = {
  openstack_auth_url:     "#{auth_url}/auth/tokens",
  openstack_username:     admin_user,
  openstack_api_key:      admin_pass,
  openstack_project_name: admin_project,
  openstack_domain_name:    admin_domain
}

# Register Compute Service
openstack_service 'nova' do
  type 'compute'
  connection_params connection_params
end

interfaces.each do |interface, res|
  # Register Compute Endpoints
  openstack_endpoint 'compute' do
    service_name 'nova'
    interface interface.to_s
    url res[:url].to_s
    region region
    connection_params connection_params
  end
end

# Register Service Tenant
openstack_project service_project_name do
  connection_params connection_params
end

# Register Service User
openstack_user service_user do
  project_name service_project_name
  role_name service_role
  password service_pass
  connection_params connection_params
end

## Grant Service role to Service User for Service Tenant ##
openstack_user service_user do
  role_name service_role
  project_name service_project_name
  connection_params connection_params
  action :grant_role
end

openstack_user service_user do
  domain_name service_domain_name
  role_name service_role
  user_name service_user
  connection_params connection_params
  action :grant_domain
end
