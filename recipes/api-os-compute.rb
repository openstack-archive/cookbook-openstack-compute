#
# Cookbook Name:: nova
# Recipe:: api-os-compute
#
# Copyright 2012, Rackspace US, Inc.
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

require "uri"

class ::Chef::Recipe
  include ::Openstack
end

include_recipe "nova::nova-common"

platform_options = node["nova"]["platform"]

directory "/var/lock/nova" do
  owner node["nova"]["user"]
  group node["nova"]["group"]
  mode  00700

  action :create
end

directory node["nova"]["api"]["auth"]["cache_dir"] do
  owner node["nova"]["user"]
  group node["nova"]["group"]
  mode 00700

  action :create
  only_if { node["openstack"]["auth"]["strategy"] == "pki" }
end

package "python-keystone" do
  action :upgrade
end

platform_options["api_os_compute_packages"].each do |pkg|
  package pkg do
    options platform_options["package_overrides"]

    action :upgrade
  end
end

service "nova-api-os-compute" do
  service_name platform_options["api_os_compute_service"]
  supports :status => true, :restart => true
  subscribes :restart, resources("template[/etc/nova/nova.conf]")

  action :enable
end

keystone_service_role = node["nova"]["keystone_service_chef_role"]
keystone = config_by_role keystone_service_role, "keystone"
identity_admin_endpoint = endpoint "identity-admin"

auth_uri = ::URI.decode identity_admin_endpoint.to_s
ksadmin_tenant_name = keystone["admin_tenant_name"]
ksadmin_user = keystone["admin_user"]
ksadmin_pass = user_password ksadmin_user
service_pass = service_password "nova"

nova_api_endpoint = endpoint "compute-api"

# Register Service Tenant
keystone_register "Register Service Tenant" do
  auth_uri auth_uri
  admin_tenant_name ksadmin_tenant_name
  admin_user ksadmin_user
  admin_password ksadmin_pass
  tenant_name node["nova"]["service_tenant_name"]
  tenant_description "Service Tenant"

  action :create_tenant
end

# Register Service User
keystone_register "Register Service User" do
  auth_uri auth_uri
  admin_tenant_name ksadmin_tenant_name
  admin_user ksadmin_user
  admin_password ksadmin_pass
  tenant_name node["nova"]["service_tenant_name"]
  user_name node["nova"]["service_user"]
  user_pass service_pass
  user_enabled "true" # Not required as this is the default

  action :create_user
end

## Grant Admin role to Service User for Service Tenant ##
keystone_register "Grant 'admin' Role to Service User for Service Tenant" do
  auth_uri auth_uri
  admin_tenant_name ksadmin_tenant_name
  admin_user ksadmin_user
  admin_password ksadmin_pass
  tenant_name node["nova"]["service_tenant_name"]
  user_name node["nova"]["service_user"]
  role_name node["nova"]["service_role"]

  action :grant_role
end

# Register Compute Service
keystone_register "Register Compute Service" do
  auth_uri auth_uri
  admin_tenant_name ksadmin_tenant_name
  admin_user ksadmin_user
  admin_password ksadmin_pass
  service_name "nova"
  service_type "compute"
  service_description "Nova Compute Service"

  action :create_service
end

# Register Compute Endpoing
keystone_register "Register Compute Endpoint" do
  auth_uri auth_uri
  admin_tenant_name ksadmin_tenant_name
  admin_user ksadmin_user
  admin_password ksadmin_pass
  service_type "compute"
  endpoint_region node["nova"]["region"]
  endpoint_adminurl ::URI.decode nova_api_endpoint.to_s
  endpoint_internalurl ::URI.decode nova_api_endpoint.to_s
  endpoint_publicurl ::URI.decode nova_api_endpoint.to_s

  action :create_endpoint
end

template "/etc/nova/api-paste.ini" do
  source "api-paste.ini.erb"
  owner  node["nova"]["user"]
  group  node["nova"]["group"]
  mode   00644
  variables(
    :identity_admin_endpoint => identity_admin_endpoint,
    :service_pass => service_pass
  )
  notifies :restart, "service[nova-api-os-compute]"
end
