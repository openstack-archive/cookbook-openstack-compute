#
# Cookbook Name:: nova
# Recipe:: volume
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
include_recipe "nova::api-os-volume"

platform_options = node["nova"]["platform"]

package "python-keystone" do
  action :upgrade
end

platform_options["nova_volume_packages"].each do |pkg|
  package pkg do
    options platform_options["package_overrides"]

    action :upgrade
  end
end

service "nova-volume" do
  service_name platform_options["nova_volume_service"]
  supports :status => true, :restart => true
  subscribes :restart, resources(:template => "/etc/nova/nova.conf"), :delayed

  action :disable
end

# TODO(rp): need the flag on whether or not to start nova-volume service
# this is already on backlog
# monitoring_procmon "nova-volume" do
#   service_name=platform_options["nova_volume_service"]

#   process_name "nova-volume"
#   start_cmd "/usr/sbin/service #{service_name} start"
#   stop_cmd "/usr/sbin/service #{service_name} stop"
# end

identity_admin_endpoint = endpoint "identity-admin"
keystone_service_role = node["nova"]["keystone_service_chef_role"]
keystone = get_settings_by_role keystone_service_role, "keystone"

volume_endpoint = endpoint "compute-volume"

# Register Volume Service
keystone_register "Register Volume Service" do
  auth_host identity_admin_endpoint.host
  auth_port identity_admin_endpoint.port.to_s
  auth_protocol identity_admin_endpoint.scheme
  api_ver identity_admin_endpoint.path
  auth_token keystone["admin_token"]
  service_name "Volume Service"
  service_type "volume"
  service_description "Nova Volume Service"

  action :create_service
end

# Register Image Endpoint
keystone_register "Register Volume Endpoint" do
  auth_host identity_admin_endpoint.host
  auth_port identity_admin_endpoint.port.to_s
  auth_protocol identity_admin_endpoint.scheme
  api_ver identity_admin_endpoint.path
  auth_token keystone["admin_token"]
  service_type "volume"
  endpoint_region "RegionOne"
  endpoint_adminurl ::URI.decode volume_endpoint.to_s
  endpoint_internalurl ::URI.decode volume_endpoint.to_s
  endpoint_publicurl ::URI.decode volume_endpoint.to_s

  action :create_endpoint
end
