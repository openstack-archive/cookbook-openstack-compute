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

include_recipe "nova::nova-common"
include_recipe "nova::api-os-volume"

platform_options = node["nova"]["platform"]

package "python-keystone" do
  action :upgrade
end

platform_options["nova_volume_packages"].each do |pkg|
  package pkg do
    action :upgrade
    options platform_options["package_overrides"]
  end
end

service "nova-volume" do
  service_name platform_options["nova_volume_service"]
  supports :status => true, :restart => true
  action :disable
  subscribes :restart, resources(:template => "/etc/nova/nova.conf"), :delayed
end

# TODO(rp): need the flag on whether or not to start nova-volume service
# this is already on backlog
# monitoring_procmon "nova-volume" do
#   service_name=platform_options["nova_volume_service"]

#   process_name "nova-volume"
#   start_cmd "/usr/sbin/service #{service_name} start"
#   stop_cmd "/usr/sbin/service #{service_name} stop"
# end

ks_admin_endpoint = get_access_endpoint("keystone", "keystone", "admin-api")
ks_service_endpoint = get_access_endpoint("keystone", "keystone", "service-api")
keystone = get_settings_by_role("keystone","keystone")
volume_endpoint = get_access_endpoint("nova-volume", "nova", "volume")

# Register Volume Service
keystone_register "Register Volume Service" do
  auth_host ks_admin_endpoint["host"]
  auth_port ks_admin_endpoint["port"]
  auth_protocol ks_admin_endpoint["scheme"]
  api_ver ks_admin_endpoint["path"]
  auth_token keystone["admin_token"]
  service_name "Volume Service"
  service_type "volume"
  service_description "Nova Volume Service"
  action :create_service
end

# Register Image Endpoint
keystone_register "Register Volume Endpoint" do
  auth_host ks_admin_endpoint["host"]
  auth_port ks_admin_endpoint["port"]
  auth_protocol ks_admin_endpoint["scheme"]
  api_ver ks_admin_endpoint["path"]
  auth_token keystone["admin_token"]
  service_type "volume"
  endpoint_region "RegionOne"
  endpoint_adminurl volume_endpoint["uri"]
  endpoint_internalurl volume_endpoint["uri"]
  endpoint_publicurl volume_endpoint["uri"]
  action :create_endpoint
end
