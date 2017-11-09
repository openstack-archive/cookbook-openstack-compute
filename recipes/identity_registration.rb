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
  admin: { url: admin_endpoint('compute-api') },
}
placement_interfaces = {
  public: { url: public_endpoint('placement-api') },
  internal: { url: internal_endpoint('placement-api') },
}
auth_url = ::URI.decode identity_admin_endpoint.to_s
service_pass = get_password 'service', 'openstack-compute'
service_user = node['openstack']['compute']['conf']['keystone_authtoken']['username']
placement_service_pass = get_password 'service', 'openstack-placement'
placement_service_user = node['openstack']['compute']['conf']['placement']['username']
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
  openstack_domain_name:  admin_domain,
}

# Register Compute Services
openstack_service 'nova' do
  type 'compute'
  connection_params connection_params
end

openstack_service 'nova-placement' do
  type 'placement'
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

placement_interfaces.each do |interface, res|
  openstack_endpoint 'placement' do
    service_name 'nova-placement'
    interface interface.to_s
    url res[:url].to_s
    region region
    connection_params connection_params
  end
end

# Register Service Project
openstack_project service_project_name do
  connection_params connection_params
end

# Register Service Users
openstack_user service_user do
  project_name service_project_name
  domain_name service_domain_name
  password service_pass
  connection_params connection_params
end

openstack_user placement_service_user do
  project_name service_project_name
  domain_name service_domain_name
  password placement_service_pass
  connection_params connection_params
end

## Grant Service role to Service Users for Service Project ##
[service_user, placement_service_user].each do |user|
  openstack_user user do
    role_name service_role
    project_name service_project_name
    connection_params connection_params
    action :grant_role
  end
end
