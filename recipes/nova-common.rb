# encoding: UTF-8
#
# Cookbook Name:: openstack-compute
# Recipe:: nova-common
#
# Copyright 2012, Rackspace US, Inc.
# Copyright 2013, Craig Tracey <craigtracey@gmail.com>
# Copyright 2014, SUSE Linux, GmbH.
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

class ::Chef::Recipe # rubocop:disable Documentation
  include ::Openstack
end

include_recipe 'openstack-common::logging' if node['openstack']['compute']['syslog']['use']

platform_options = node['openstack']['compute']['platform']

platform_options['common_packages'].each do |pkg|
  package pkg do
    options platform_options['package_overrides']
    action :upgrade
  end
end

db_type = node['openstack']['db']['compute']['service_type']
node['openstack']['db']['python_packages'][db_type].each do |pkg|
  package pkg do
    options platform_options['package_overrides']
    action :upgrade
  end
end

# required to run more than one consoleauth process
platform_options['memcache_python_packages'].each do |pkg|
  package pkg do
    options platform_options['package_overrides']
    action :upgrade
  end
end

directory '/etc/nova' do
  owner node['openstack']['compute']['user']
  group node['openstack']['compute']['group']
  mode  00750
  action :create
end

directory node['openstack']['compute']['state_path'] do
  owner node['openstack']['compute']['user']
  group node['openstack']['compute']['group']
  mode 00755
  recursive true
end

directory node['openstack']['compute']['lock_path'] do
  owner node['openstack']['compute']['user']
  group node['openstack']['compute']['group']
  mode 00755
  recursive true
end

db_user = node['openstack']['db']['compute']['username']
db_pass = get_password 'db', 'nova'
sql_connection = db_uri('compute', db_user, db_pass)

mq_service_type = node['openstack']['mq']['compute']['service_type']

if mq_service_type == 'rabbitmq'
  node['openstack']['mq']['compute']['rabbit']['ha'] && (rabbit_hosts = rabbit_servers)
  mq_password = get_password 'user', node['openstack']['mq']['compute']['rabbit']['userid']
elsif mq_service_type == 'qpid'
  mq_password = get_password 'user', node['openstack']['mq']['compute']['qpid']['username']
end

memcache_servers = memcached_servers.join ','

# find the node attribute endpoint settings for the server holding a given role
identity_endpoint = endpoint 'identity-api'
xvpvnc_endpoint = endpoint 'compute-xvpvnc' || {}
xvpvnc_bind = endpoint 'compute-xvpvnc-bind' || {}
novnc_endpoint = endpoint 'compute-novnc' || {}
novnc_bind = endpoint 'compute-novnc-bind' || {}
vnc_bind = endpoint 'compute-vnc-bind' || {}
compute_api_bind = endpoint 'compute-api-bind' || {}
compute_api_endpoint = endpoint 'compute-api' || {}
ec2_api_bind = endpoint 'compute-ec2-api-bind' || {}
ec2_public_endpoint = endpoint 'compute-ec2-api' || {}
network_endpoint = endpoint 'network-api' || {}
image_endpoint = endpoint 'image-api'

Chef::Log.debug("openstack-compute::nova-common:identity_endpoint|#{identity_endpoint.to_s}")
Chef::Log.debug("openstack-compute::nova-common:xvpvnc_endpoint|#{xvpvnc_endpoint.to_s}")
Chef::Log.debug("openstack-compute::nova-common:novnc_endpoint|#{novnc_endpoint.to_s}")
Chef::Log.debug("openstack-compute::nova-common:compute_api_endpoint|#{::URI.decode compute_api_endpoint.to_s}")
Chef::Log.debug("openstack-compute::nova-common:ec2_public_endpoint|#{ec2_public_endpoint.to_s}")
Chef::Log.debug("openstack-compute::nova-common:network_endpoint|#{network_endpoint.to_s}")
Chef::Log.debug("openstack-compute::nova-common:image_endpoint|#{image_endpoint.to_s}")

if node['openstack']['compute']['network']['service_type'] == 'neutron'
  neutron_admin_password = get_password 'service', 'openstack-network'
  neutron_metadata_proxy_shared_secret = get_secret 'neutron_metadata_secret'
end

if node['openstack']['compute']['libvirt']['images_type'] == 'rbd'
  rbd_secret_uuid = get_secret node['openstack']['compute']['libvirt']['rbd']['rbd_secret_name']
end

if node['openstack']['compute']['driver'].split('.').first == 'vmwareapi'
  vmware_host_pass = get_secret node['openstack']['compute']['vmware']['secret_name']
end

identity_admin_endpoint = endpoint 'identity-admin'
auth_uri = auth_uri_transform identity_endpoint.to_s, node['openstack']['compute']['api']['auth']['version']
service_pass = get_password 'service', 'openstack-compute'

template '/etc/nova/nova.conf' do
  source 'nova.conf.erb'
  owner node['openstack']['compute']['user']
  group node['openstack']['compute']['group']
  mode 00644
  variables(
    sql_connection: sql_connection,
    novncproxy_base_url: novnc_endpoint.to_s,
    xvpvncproxy_base_url: xvpvnc_endpoint.to_s,
    xvpvncproxy_bind_host: xvpvnc_bind.host,
    xvpvncproxy_bind_port: xvpvnc_bind.port,
    novncproxy_bind_host: novnc_bind.host,
    novncproxy_bind_port: novnc_bind.port,
    vncserver_listen: vnc_bind.host,
    vncserver_proxyclient_address: vnc_bind.host,
    memcache_servers: memcache_servers,
    mq_service_type: mq_service_type,
    mq_password: mq_password,
    rabbit_hosts: rabbit_hosts,
    identity_endpoint: identity_endpoint,
    # TODO(jaypipes): No support here for >1 image API servers
    # with the glance_api_servers configuration option...
    glance_api_ipaddress: image_endpoint.host,
    glance_api_port: image_endpoint.port,
    iscsi_helper: platform_options['iscsi_helper'],
    scheduler_default_filters: node['openstack']['compute']['scheduler']['default_filters'].join(','),
    osapi_compute_link_prefix: compute_api_endpoint.to_s,
    network_endpoint: network_endpoint,
    neutron_admin_password: neutron_admin_password,
    neutron_metadata_proxy_shared_secret: neutron_metadata_proxy_shared_secret,
    compute_api_bind_ip: compute_api_bind.host,
    compute_api_bind_port: compute_api_bind.port,
    ec2_api_bind_ip: ec2_api_bind.host,
    ec2_api_bind_port: ec2_api_bind.port,
    rbd_secret_uuid: rbd_secret_uuid,
    vmware_host_pass: vmware_host_pass,
    auth_uri: auth_uri,
    identity_admin_endpoint: identity_admin_endpoint,
    service_pass: service_pass
  )
end

template '/etc/nova/rootwrap.conf' do
  source 'rootwrap.conf.erb'
  # Must be root!
  owner  'root'
  group  'root'
  mode   00644
end

execute 'enable nova login' do
  command "usermod -s /bin/sh #{node['openstack']['compute']['user']}"
end
