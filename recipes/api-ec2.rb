#
# Cookbook Name:: nova
# Recipe:: api
#
# Copyright 2009, Rackspace Hosting, Inc.
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

include_recipe "nova::nova-common"

#TODO(breu): test for fedora
# Distribution specific settings go here
if platform?(%w{fedora})
  # Fedora
  nova_api_ec2_package = "openstack-nova"
  nova_api_ec2_service = "openstack-nova-api"
  nova_api_ec2_package_options = ""
else
  # All Others (right now Debian and Ubuntu)
  nova_api_ec2_package = "nova-api-ec2"
  nova_api_ec2_service = nova_api_ec2_package
  nova_api_ec2_package_options = "-o Dpkg::Options::='--force-confold' --force-yes"
end

directory "/var/lock/nova" do
    owner "nova"
    group "nova"
    mode "0755"
    action :create
end

package "python-keystone" do
  action :upgrade
end

package nova_api_ec2_package do
  action :upgrade
  options nova_api_ec2_package_options
end

service nova_api_ec2_service do
  supports :status => true, :restart => true
  action :enable
  subscribes :restart, resources(:template => "/etc/nova/nova.conf"), :delayed
end

if Chef::Config[:solo]
  Chef::Log.warn("This recipe uses search. Chef Solo does not support search.")
else
  # Lookup keystone api ip address
  keystone, something, arbitrary_value = Chef::Search::Query.new.search(:node, "roles:keystone AND chef_environment:#{node.chef_environment}")
  if keystone.length > 0
    Chef::Log.info("nova::api-ec2/keystone: using search")
    keystone_api_ip = keystone[0]['keystone']['api_ipaddress']
    keystone_service_port = keystone[0]['keystone']['service_port']
    keystone_admin_port = keystone[0]['keystone']['admin_port']
    keystone_admin_token = keystone[0]['keystone']['admin_token']
  else
    Chef::Log.info("nova::api-ec2/keystone: NOT using search")
    keystone_api_ip = node['keystone']['api_ipaddress']
    keystone_service_port = node['keystone']['service_port']
    keystone_admin_port = node['keystone']['admin_port']
    keystone_admin_token = node['keystone']['admin_token']
  end
end

# Register Service Tenant
keystone_register "Register Service Tenant" do
  auth_host keystone_api_ip
  auth_port keystone_admin_port
  auth_protocol "http"
  api_ver "/v2.0"
  auth_token keystone_admin_token
  tenant_name node["nova"]["service_tenant_name"]
  tenant_description "Service Tenant"
  tenant_enabled "true" # Not required as this is the default
  action :create_tenant
end

# Register Service User
keystone_register "Register Service User" do
  auth_host keystone_api_ip
  auth_port keystone_admin_port
  auth_protocol "http"
  api_ver "/v2.0"
  auth_token keystone_admin_token
  tenant_name node["nova"]["service_tenant_name"]
  user_name node["nova"]["service_user"]
  user_pass node["nova"]["service_pass"]
  user_enabled "true" # Not required as this is the default
  action :create_user
end

## Grant Admin role to Service User for Service Tenant ##
keystone_register "Grant 'admin' Role to Service User for Service Tenant" do
  auth_host keystone_api_ip
  auth_port keystone_admin_port
  auth_protocol "http"
  api_ver "/v2.0"
  auth_token keystone_admin_token
  tenant_name node["nova"]["service_tenant_name"]
  user_name node["nova"]["service_user"]
  role_name node["nova"]["service_role"]
  action :grant_role
end

# Register EC2 Service
keystone_register "Register EC2 Service" do
  auth_host keystone_api_ip
  auth_port keystone_admin_port
  auth_protocol "http"
  api_ver "/v2.0"
  auth_token keystone_admin_token
  service_name "ec2"
  service_type "ec2"
  service_description "EC2 Compatibility Layer"
  action :create_service
end

template "/etc/nova/api-paste.ini" do
  source "api-paste.ini.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(
    :ip_address => node["controller_ipaddress"],
    :component  => node["package_component"],
    :service_port => keystone_service_port,
    :keystone_api_ipaddress => keystone_api_ip,
    :admin_port => keystone_admin_port,
    :admin_token => keystone_admin_token
  )
  notifies :restart, resources(:service => nova_api_ec2_service), :delayed
end

node["nova"]["ec2"]["adminURL"] = "http://#{node["nova"]["api_ipaddress"]}:8773/services/Admin"
node["nova"]["ec2"]["publicURL"] = "http://#{node["nova"]["api_ipaddress"]}:8773/services/Cloud"
node["nova"]["ec2"]["internalURL"] = node["nova"]["ec2"]["publicURL"]

# Register EC2 Endpoint
keystone_register "Register Compute Endpoint" do
  auth_host keystone_api_ip
  auth_port keystone_admin_port
  auth_protocol "http"
  api_ver "/v2.0"
  auth_token keystone_admin_token
  service_type "ec2"
  endpoint_region "RegionOne"
  endpoint_adminurl node["nova"]["ec2"]["adminURL"]
  endpoint_internalurl node["nova"]["ec2"]["internalURL"]
  endpoint_publicurl node["nova"]["ec2"]["publicURL"]
  action :create_endpoint
end
