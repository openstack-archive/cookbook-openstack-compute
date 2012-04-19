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
  nova_api_metadata_package = "openstack-nova"
  nova_api_metadata_service = "openstack-nova-api"
  nova_api_metadata_package_options = ""
else
  # All Others (right now Debian and Ubuntu)
  nova_api_metadata_package = "nova-api-metadata"
  nova_api_metadata_service = nova_api_metadata_package
  nova_api_metadata_package_options = "-o Dpkg::Options::='--force-confold' --force-yes"
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

package nova_api_metadata_package do
  action :upgrade
  options nova_api_metadata_package_options
end

service nova_api_metadata_service do
  supports :status => true, :restart => true
  action :enable
  subscribes :restart, resources(:template => "/etc/nova/nova.conf"), :delayed
end

if Chef::Config[:solo]
  Chef::Log.warn("This recipe uses search. Chef Solo does not support search.")
else
  # Lookup keystone api ip address
  keystone = search(:node, "recipe:keystone\\:\\:server and chef_environment:#{node.chef_environment}")
  if keystone[0].length > 0
    Chef::Log.info("Using Keystone attributes from SEARCH")
    keystone_api_ip = keystone[0]['keystone']['api_ipaddress']
    keystone_service_port = keystone[0]['keystone']['service_port']
    keystone_admin_port = keystone[0]['keystone']['admin_port']
    keystone_admin_token = keystone[0]['keystone']['admin_token']
  else
    Chef::Log.info("Using Keystone attributes from NODE")
    keystone_api_ip = node['keystone']['api_ipaddress']
    keystone_service_port = node['keystone']['service_port']
    keystone_admin_port = node['keystone']['admin_port']
    keystone_admin_token = node['keystone']['admin_token']
  end
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
  notifies :restart, resources(:service => nova_api_metadata_service), :delayed
end
