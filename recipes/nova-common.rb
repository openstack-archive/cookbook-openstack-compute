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

require "uri"

class ::Chef::Recipe
  include ::Openstack
end

if platform?(%w(redhat centos))
  include_recipe "yum::epel"
end

platform_options = node["nova"]["platform"]

platform_options["common_packages"].each do |pkg|
  package pkg do
    options platform_options["package_overrides"]

    action :upgrade
  end
end

directory "/etc/nova" do
  owner node["nova"]["user"]
  group node["nova"]["group"]
  mode  00700

  action :create
end

rabbit_server_role = node["nova"]["rabbit_server_chef_role"]
rabbit_info = get_settings_by_role rabbit_server_role, "queue"

# Still need this but only to get the nova db password...
# TODO(jaypipes): Refactor password generation/lookup into
# openstack-common.
nova_setup_role = node["nova"]["nova_setup_chef_role"]
nova_setup_info = get_settings_by_role nova_setup_role, "nova"

db_user = node['nova']['db']['username']
db_pass = nova_setup_info['db']['password']
sql_connection = db_uri("compute", db_user, db_pass)

keystone_service_role = node["nova"]["keystone_service_chef_role"]
keystone = get_settings_by_role keystone_service_role, "keystone"

# find the node attribute endpoint settings for the server holding a given role
identity_admin_endpoint = endpoint "identity-admin"
identity_endpoint = endpoint "identity-api"
xvpvnc_endpoint = endpoint "compute-xvpvnc" || {}
novnc_endpoint = endpoint "compute-novnc-server" || {}
novnc_proxy_endpoint = endpoint "compute-novnc"
nova_api_endpoint = endpoint "compute-api" || {}
ec2_public_endpoint = endpoint "compute-ec2-api" || {}
image_endpoint = endpoint "image-api"

Chef::Log.debug("nova::nova-common:rabbit_info|#{rabbit_info}")
Chef::Log.debug("nova::nova-common:keystone|#{keystone}")
Chef::Log.debug("nova::nova-common:identity_endpoint|#{identity_endpoint.to_s}")
Chef::Log.debug("nova::nova-common:xvpvnc_endpoint|#{xvpvnc_endpoint.to_s}")
Chef::Log.debug("nova::nova-common:novnc_endpoint|#{novnc_endpoint.to_s}")
Chef::Log.debug("nova::nova-common:novnc_proxy_endpoint|#{novnc_proxy_endpoint.to_s}")
Chef::Log.debug("nova::nova-common:nova_api_endpoint|#{::URI.decode nova_api_endpoint.to_s}")
Chef::Log.debug("nova::nova-common:ec2_public_endpoint|#{ec2_public_endpoint.to_s}")
Chef::Log.debug("nova::nova-common:image_endpoint|#{image_endpoint.to_s}")

# TODO: need to re-evaluate this for accuracy
template "/etc/nova/nova.conf" do
  source "nova.conf.erb"
  owner  "root"
  group  "root"
  mode   00644
  variables(
    :sql_connection => sql_connection,
    :vncserver_listen => "0.0.0.0",
    :vncserver_proxyclient_address => novnc_proxy_endpoint.host,
    :novncproxy_base_url => novnc_endpoint.to_s,
    :xvpvncproxy_bind_host => xvpvnc_endpoint.host,
    :xvpvncproxy_bind_port => xvpvnc_endpoint.port,
    :xvpvncproxy_base_url => xvpvnc_endpoint.to_s,
    :rabbit_ipaddress => rabbit_info["host"],
    :rabbit_port => rabbit_info["port"],
    :identity_endpoint => identity_endpoint,
    # TODO(jaypipes): No support here for >1 image API servers
    # with the glance_api_servers configuration option...
    :glance_api_ipaddress => image_endpoint.host,
    :glance_api_port => image_endpoint.port,
    :iscsi_helper => platform_options["iscsi_helper"],
    :scheduler_default_filters => node["nova"]["scheduler"]["default_filters"].join(",")
  )
end

# TODO: need to re-evaluate this for accuracy
template "/root/openrc" do
  source "openrc.erb"
  owner  "root"
  group  "root"
  mode   00600
  variables(
    :user => keystone["admin_user"],
    :tenant => keystone["users"][keystone["admin_user"]]["default_tenant"],
    :password => keystone["users"][keystone["admin_user"]]["password"],
    :identity_admin_endpoint => identity_admin_endpoint,
    :nova_api_ipaddress => nova_api_endpoint.host,
    :nova_api_version => "1.1",
    :auth_strategy => "keystone",
    :ec2_url => ec2_public_endpoint.to_s
  )
end

execute "enable nova login" do
  command "usermod -s /bin/sh nova"
end
