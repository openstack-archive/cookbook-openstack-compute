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

rabbit_server_role = node["nova"]["rabbit_server_chef_role"]
rabbit_info = get_settings_by_role(rabbit_server_role, "queue")

# Still need this but only to get the nova db password...
# TODO(jaypipes): Refactor password generation/lookup into
# openstack-common.
nova_setup_role = node["nova"]["nova_setup_chef_role"]
nova_setup_info = get_settings_by_role(nova_setup_role, "nova")

db_user = node['db']['username']
db_pass = nova_setup_info['db']['password']
sql_connection = ::Openstack::db_uri("compute", db_user, db_pass)

keystone_service_role = node["nova"]["keystone_service_chef_role"]
keystone = get_settings_by_role(keystone_service_role, "keystone")

# find the node attribute endpoint settings for the server holding a given role
identity_endpoint = ::Openstack::endpoint('identity-api')
xvpvnc_endpoint = ::Openstack::endpoint('compute-xvpvnc') || {}
novnc_endpoint = ::Openstack::endpoint('compute-novnc-server') || {}
novnc_proxy_endpoint = ::Openstack::endpoint('compute-novnc')
nova_api_endpoint = ::Openstack::endpoint('compute-api') || {}
ec2_public_endpoint = ::Openstack::endpoint('compute-ec2-api') || {}
image_endpoint = ::Openstack::endpoint('image-api')

Chef::Log.debug("nova::nova-common:rabbit_info|#{rabbit_info}")
Chef::Log.debug("nova::nova-common:keystone|#{keystone}")
Chef::Log.debug("nova::nova-common:identity_endpoint|#{identity_endpoint}")
Chef::Log.debug("nova::nova-common:xvpvnc_endpoint|#{xvpvnc_endpoint}")
Chef::Log.debug("nova::nova-common:novnc_endpoint|#{novnc_endpoint}")
Chef::Log.debug("nova::nova-common:novnc_proxy_endpoint|#{novnc_proxy_endpoint}")
Chef::Log.debug("nova::nova-common:nova_api_endpoint|#{nova_api_endpoint}")
Chef::Log.debug("nova::nova-common:ec2_public_endpoint|#{ec2_public_endpoint}")
Chef::Log.debug("nova::nova-common:image_endpoint|#{image_endpoint}")

# TODO: need to re-evaluate this for accuracy
template "/etc/nova/nova.conf" do
  source "nova.conf.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(
    "custom_template_banner" => node["nova"]["custom_template_banner"],
    "use_syslog" => node["nova"]["syslog"]["use"],
    "log_facility" => node["nova"]["syslog"]["facility"],
    "sql_connection" => sql_connection,
    "vncserver_listen" => "0.0.0.0",
    "vncserver_proxyclient_address" => novnc_proxy_endpoint["host"],
    "novncproxy_base_url" => novnc_endpoint["uri"],
    "xvpvncproxy_bind_host" => xvpvnc_endpoint["host"],
    "xvpvncproxy_bind_port" => xvpvnc_endpoint["port"],
    "xvpvncproxy_base_url" => xvpvnc_endpoint["uri"],
    "rabbit_ipaddress" => rabbit_info["host"],
    "rabbit_port" => rabbit_info["port"],
    "keystone_api_ipaddress" => identity_endpoint["host"],
    "keystone_service_port" => identity_endpoint["port"],
    # TODO(jaypipes): No support here for >1 image API servers
    # with the glance_api_servers configuration option...
    "glance_api_ipaddress" => image_endpoint["host"],
    "glance_api_port" => image_endpoint["port"],
    "iscsi_helper" => platform_options["iscsi_helper"],
    "public_interface" => node["nova"]["network"]["public_interface"],
    "vlan_interface" => node["nova"]["network"]["vlan_interface"],
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
    "custom_template_banner" => node["nova"]["custom_template_banner"],
    "user" => keystone["admin_user"],
    "tenant" => keystone["users"][keystone["admin_user"]]["default_tenant"],
    "password" => keystone["users"][keystone["admin_user"]]["password"],
    "keystone_api_ipaddress" => identity_endpoint["host"],
    "keystone_service_port" => identity_endpoint["port"],
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
