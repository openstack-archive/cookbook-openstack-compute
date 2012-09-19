#
# Cookbook Name:: nova
# Recipe:: nova-common
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

include_recipe "osops-utils::autoetchosts"

if platform?(%w(redhat centos))
  include_recipe "yum::epel"
end

platform_options = node["nova"]["platform"]

platform_options["common_packages"].each do |pkg|
  package pkg do
    action :upgrade
    options platform_options["package_overrides"]
  end
end

directory "/etc/nova" do
  action :create
  owner "nova"
  group "nova"
  mode "0755"
end

mysql_info = get_access_endpoint("mysql-master", "mysql", "db")
rabbit_info = get_access_endpoint("rabbitmq-server", "rabbitmq", "queue")

# nova::nova-setup does not need to be double escaped here
nova_setup_info = get_settings_by_role("nova-setup", "nova")
keystone = get_settings_by_role("keystone", "keystone")

# find the node attribute endpoint settings for the server holding a given role
ks_admin_endpoint = get_access_endpoint("keystone", "keystone", "admin-api")
ks_service_endpoint = get_access_endpoint("keystone", "keystone", "service-api")
xvpvnc_endpoint = get_access_endpoint("nova-vncproxy", "nova", "xvpvnc") || {}
novnc_endpoint = get_access_endpoint("nova-vncproxy", "nova", "novnc-server") || {}
novnc_proxy_endpoint = get_bind_endpoint("nova", "novnc")

glance_endpoint = get_access_endpoint("glance-api", "glance", "api")
nova_api_endpoint = get_access_endpoint("nova-api-os-compute", "nova", "api") || {}
ec2_public_endpoint = get_access_endpoint("nova-api-ec2", "nova", "ec2-public") || {}

Chef::Log.debug("nova::nova-common:mysql_info|#{mysql_info}")
Chef::Log.debug("nova::nova-common:rabbit_ip|#{rabbit_info}")
Chef::Log.debug("nova::nova-common:nova_setup_info|#{nova_setup_info}")
Chef::Log.debug("nova::nova-common:keystone|#{keystone}")
Chef::Log.debug("nova::nova-common:ks_admin_endpoint|#{ks_admin_endpoint}")
Chef::Log.debug("nova::nova-common:ks_service_endpoint|#{ks_service_endpoint}")
Chef::Log.debug("nova::nova-common:xvpvnc_endpoint|#{xvpvnc_endpoint}")
Chef::Log.debug("nova::nova-common:novnc_endpoint|#{novnc_endpoint}")
Chef::Log.debug("nova::nova-common:novnc_proxy_endpoint|#{novnc_proxy_endpoint}")
Chef::Log.debug("nova::nova-common:glance_endpoint|#{glance_endpoint}")
Chef::Log.debug("nova::nova-common:nova_api_endpoint|#{nova_api_endpoint}")
Chef::Log.debug("nova::nova-common:ec2_public_endpoint|#{ec2_public_endpoint}")

# TODO: need to re-evaluate this for accuracy
template "/etc/nova/nova.conf" do
  source "nova.conf.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(
    "use_syslog" => node["nova"]["syslog"]["use"],
    "log_facility" => node["nova"]["syslog"]["facility"],
    "db_ipaddress" => mysql_info["host"],
    "user" => node["nova"]["db"]["username"],
    "passwd" => nova_setup_info["db"]["password"],
    "db_name" => node["nova"]["db"]["name"],
    "vncserver_listen" => "0.0.0.0",
    "vncserver_proxyclient_address" => novnc_proxy_endpoint["host"],
    "novncproxy_base_url" => novnc_endpoint["uri"],
    "xvpvncproxy_bind_host" => xvpvnc_endpoint["host"],
    "xvpvncproxy_bind_port" => xvpvnc_endpoint["port"],
    "xvpvncproxy_base_url" => xvpvnc_endpoint["uri"],
    "rabbit_ipaddress" => rabbit_info["host"],
    "rabbit_port" => rabbit_info["port"],
    "keystone_api_ipaddress" => ks_admin_endpoint["host"],
    "keystone_service_port" => ks_service_endpoint["port"],
    "glance_api_ipaddress" => glance_endpoint["host"],
    "glance_api_port" => glance_endpoint["port"],
    "iscsi_helper" => platform_options["iscsi_helper"],
    "public_interface" => node["nova"]["network"]["public_interface"],
    "network_manager" => node["nova"]["network"]["network_manager"],
    "scheduler_driver" => node["nova"]["scheduler"]["scheduler_driver"],
    "scheduler_default_filters" => node["nova"]["scheduler"]["default_filters"].join(","),
    "availability_zone" => node["nova"]["config"]["availability_zone"],
    "default_schedule_zone" => node["nova"]["config"]["default_schedule_zone"],
    "virt_type" => node["nova"]["libvirt"]["virt_type"],
    "remove_unused_base_images" => node["nova"]["libvirt"]["remove_unused_base_images"],
    "remove_unused_resized_minimum_age_seconds" => node["nova"]["libvirt"]["remove_unused_resized_minimum_age_seconds"],
    "remove_unused_original_minimum_age_seconds" => node["nova"]["libvirt"]["remove_unused_original_minimum_age_seconds"],
    "checksum_base_images" => node["nova"]["libvirt"]["checksum_base_images"],
    "fixed_range" => node["nova"]["network"]["fixed_range"],
    "force_raw_images" => node["nova"]["config"]["force_raw_images"],
    "dmz_cidr" => node["nova"]["network"]["dmz_cidr"],
    "allow_same_net_traffic" => node["nova"]["config"]["allow_same_net_traffic"],
    "osapi_max_limit" => node["nova"]["config"]["osapi_max_limit"],
    "cpu_allocation_ratio" => node["nova"]["config"]["cpu_allocation_ratio"],
    "ram_allocation_ratio" => node["nova"]["config"]["ram_allocation_ratio"],
    "snapshot_image_format" => node["nova"]["config"]["snapshot_image_format"],
    "start_guests_on_host_boot" => node["nova"]["config"]["start_guests_on_host_boot"],
    "resume_guests_state_on_host_boot" => node["nova"]["config"]["resume_guests_state_on_host_boot"],
    "quota_security_groups" => node["nova"]["config"]["quota_security_groups"],
    "quota_security_group_rules" => node["nova"]["config"]["quota_security_group_rules"]
  )
end

# TODO: need to re-evaluate this for accuracy
template "/root/openrc" do
  source "openrc.erb"
  owner "root"
  group "root"
  mode "0600"
  variables(
    "user" => keystone["admin_user"],
    "tenant" => keystone["users"][keystone["admin_user"]]["default_tenant"],
    "password" => keystone["users"][keystone["admin_user"]]["password"],
    "keystone_api_ipaddress" => ks_service_endpoint["host"],
    "keystone_service_port" => ks_service_endpoint["port"],
    "nova_api_ipaddress" => nova_api_endpoint["host"],
    "nova_api_version" => "1.1",
    "keystone_region" => node["nova"]["compute"]["region"],
    "auth_strategy" => "keystone",
    "ec2_url" => ec2_public_endpoint["uri"],
    "ec2_access_key" => node["credentials"]["EC2"]["admin"]["access"],
    "ec2_secret_key" => node["credentials"]["EC2"]["admin"]["secret"]
  )
end

execute "enable nova login" do
  command "usermod -s /bin/sh nova"
end
