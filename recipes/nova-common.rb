#
# Cookbook Name:: openstack-compute
# Recipe:: nova-common
#
# Copyright 2012, Rackspace US, Inc.
# Copyright 2013, Craig Tracey <craigtracey@gmail.com>
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

if platform?(%w(fedora redhat centos)) # :pragma-foodcritic: ~FC024 - won't fix this
  include_recipe "yum::epel"
end
if node["openstack"]["compute"]["syslog"]["use"]
  include_recipe "openstack-common::logging"
end

platform_options = node["openstack"]["compute"]["platform"]

platform_options["common_packages"].each do |pkg|
  package pkg do
    options platform_options["package_overrides"]

    action :upgrade
  end
end

# required to run more than one consoleauth process
platform_options["memcache_python_packages"].each do |pkg|
  package pkg do
    action :install
  end
end

directory "/etc/nova" do
  owner node["openstack"]["compute"]["user"]
  group node["openstack"]["compute"]["group"]
  mode  00700

  action :create
end

directory "/etc/nova/rootwrap.d" do
  # Must be root!
  owner "root"
  group "root"
  mode  00700

  action :create
end

rabbit_server_role = node["openstack"]["compute"]["rabbit_server_chef_role"]
rabbit_info = config_by_role rabbit_server_role, "queue"

db_user = node["openstack"]["compute"]["db"]["username"]
db_pass = db_password "nova"
sql_connection = db_uri("compute", db_user, db_pass)

rabbit_user = rabbit_info && rabbit_info["username"] || node["openstack"]["compute"]["rabbit"]["username"]
rabbit_pass = user_password rabbit_user
rabbit_vhost = rabbit_info && rabbit_info["vhost"] || node["openstack"]["compute"]["rabbit"]["vhost"]

identity_service_role = node["openstack"]["compute"]["identity_service_chef_role"]
keystone = config_by_role identity_service_role, "openstack-identity"

ksadmin_tenant_name = keystone["admin_tenant_name"]
ksadmin_user = keystone["admin_user"]
ksadmin_pass = user_password ksadmin_user

memcache_servers = memcached_servers.join ","

# find the node attribute endpoint settings for the server holding a given role
identity_admin_endpoint = endpoint "identity-admin"
identity_endpoint = endpoint "identity-api"
xvpvnc_endpoint = endpoint "compute-xvpvnc" || {}
novnc_endpoint = endpoint "compute-novnc" || {}
compute_api_endpoint = endpoint "compute-api" || {}
ec2_public_endpoint = endpoint "compute-ec2-api" || {}
image_endpoint = endpoint "image-api"

Chef::Log.debug("openstack-compute::nova-common:rabbit_info|#{rabbit_info}")
Chef::Log.debug("openstack-compute::nova-common:keystone|#{keystone}")
Chef::Log.debug("openstack-compute::nova-common:identity_endpoint|#{identity_endpoint.to_s}")
Chef::Log.debug("openstack-compute::nova-common:xvpvnc_endpoint|#{xvpvnc_endpoint.to_s}")
Chef::Log.debug("openstack-compute::nova-common:novnc_endpoint|#{novnc_endpoint.to_s}")
Chef::Log.debug("openstack-compute::nova-common:compute_api_endpoint|#{::URI.decode compute_api_endpoint.to_s}")
Chef::Log.debug("openstack-compute::nova-common:ec2_public_endpoint|#{ec2_public_endpoint.to_s}")
Chef::Log.debug("openstack-compute::nova-common:image_endpoint|#{image_endpoint.to_s}")

vnc_bind_ip = node["network"]["ipaddress_#{node["openstack"]["compute"]["libvirt"]["bind_interface"]}"]
xvpvnc_proxy_ip = node["network"]["ipaddress_#{node["openstack"]["compute"]["xvpvnc_proxy"]["bind_interface"]}"]
novnc_proxy_ip = node["network"]["ipaddress_#{node["openstack"]["compute"]["novnc_proxy"]["bind_interface"]}"]

template "/etc/nova/nova.conf" do
  source "nova.conf.erb"
  owner node["openstack"]["compute"]["user"]
  group node["openstack"]["compute"]["group"]
  mode 00644
  variables(
    :sql_connection => sql_connection,
    :novncproxy_base_url => novnc_endpoint.to_s,
    :xvpvncproxy_base_url => xvpvnc_endpoint.to_s,
    :xvpvncproxy_bind_host => xvpvnc_proxy_ip,
    :novncproxy_bind_host => novnc_proxy_ip,
    :vncserver_listen => vnc_bind_ip,
    :vncserver_proxyclient_address => vnc_bind_ip,
    :memcache_servers => memcache_servers,
    :rabbit_ipaddress => rabbit_info["host"],
    :rabbit_user => rabbit_user,
    :rabbit_password => rabbit_pass,
    :rabbit_port => rabbit_info["port"],
    :rabbit_virtual_host => rabbit_vhost,
    :identity_endpoint => identity_endpoint,
    # TODO(jaypipes): No support here for >1 image API servers
    # with the glance_api_servers configuration option...
    :glance_api_ipaddress => image_endpoint.host,
    :glance_api_port => image_endpoint.port,
    :iscsi_helper => platform_options["iscsi_helper"],
    :scheduler_default_filters => node["openstack"]["compute"]["scheduler"]["default_filters"].join(","),
    :osapi_compute_link_prefix => compute_api_endpoint.to_s
  )
end

template "/etc/nova/rootwrap.conf" do
  source "rootwrap.conf.erb"
  # Must be root!
  owner  "root"
  group  "root"
  mode   00644
end

template "/etc/nova/rootwrap.d/api-metadata.filters" do
  source "rootwrap.d/api-metadata.filters.erb"
  # Must be root!
  owner  "root"
  group  "root"
  mode   00644
end

template "/etc/nova/rootwrap.d/compute.filters" do
  source "rootwrap.d/compute.filters.erb"
  # Must be root!
  owner  "root"
  group  "root"
  mode   00644
end

template "/etc/nova/rootwrap.d/network.filters" do
  source "rootwrap.d/network.filters.erb"
  # Must be root!
  owner  "root"
  group  "root"
  mode   00644
end

# TODO: need to re-evaluate this for accuracy
# TODO(jaypipes): This should be moved into openstack-common
# and evaluated only on nodes with admin privs.
template "/root/openrc" do
  source "openrc.erb"
  # Must be root!
  owner  "root"
  group  "root"
  mode   00600
  variables(
    :user => ksadmin_user,
    :tenant => ksadmin_tenant_name,
    :password => ksadmin_pass,
    :identity_endpoint => identity_endpoint,
    :auth_strategy => "keystone",
    :ec2_url => ec2_public_endpoint.to_s
  )
end

execute "enable nova login" do
  command "usermod -s /bin/sh #{node["openstack"]["compute"]["user"]}"
end
