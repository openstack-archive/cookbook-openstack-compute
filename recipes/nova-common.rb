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

require 'uri'

# Make Openstack object available in Chef::Recipe
class ::Chef::Recipe
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
  mode 00750
  action :create
end

directory node['openstack']['compute']['conf']['DEFAULT']['state_path'] do
  owner node['openstack']['compute']['user']
  group node['openstack']['compute']['group']
  mode 00755
  recursive true
end

directory node['openstack']['compute']['conf']['oslo_concurrency']['lock_path'] do
  owner node['openstack']['compute']['user']
  group node['openstack']['compute']['group']
  mode 00755
  recursive true
end

db_user = node['openstack']['db']['compute']['username']
db_pass = get_password 'db', 'nova'
node.default['openstack']['compute']['conf_secrets']
  .[]('database')['connection'] =
  db_uri('compute', db_user, db_pass)

if node['openstack']['endpoints']['db']['enabled_slave']
  node.default['openstack']['compute']['conf_secrets']
    .[]('database')['slave_connection'] =
    db_uri('compute', db_user, db_pass, true)
end

if node['openstack']['compute']['conf']['DEFAULT']['rpc_backend'] == 'rabbit'
  user = node['openstack']['mq']['compute']['rabbit']['userid']
  node.default['openstack']['compute']['conf_secrets']
    .[]('oslo_messaging_rabbit')['rabbit_userid'] = user
  node.default['openstack']['compute']['conf_secrets']
    .[]('oslo_messaging_rabbit')['rabbit_password'] =
    get_password 'user', user
end

memcache_servers = memcached_servers.join ','

# find the node attribute endpoint settings for the server holding a given role
# Note that the bind and vnc endpoints don't have possible different values for
# internal/admin/public. We'll stick with the general endpoint routine
# for those.
identity_endpoint = public_endpoint 'identity'
xvpvnc_endpoint = public_endpoint 'compute-xvpvnc'
xvpvnc_bind = node['openstack']['bind_service']['all']['compute-xvpvnc']
xvpvnc_bind_address = bind_address xvpvnc_bind
novnc_endpoint = public_endpoint 'compute-novnc'
novnc_bind = node['openstack']['bind_service']['all']['compute-novnc']
novnc_bind_address = bind_address novnc_bind
vnc_bind = node['openstack']['bind_service']['all']['compute-vnc']
vnc_bind_address = bind_address vnc_bind
vnc_proxy_bind = node['openstack']['bind_service']['all']['compute-vnc-proxy']
vnc_proxy_bind_address = bind_address vnc_proxy_bind
compute_api_bind = node['openstack']['bind_service']['all']['compute-api']
compute_api_bind_address = bind_address compute_api_bind
compute_api_endpoint = internal_endpoint 'compute-api'
compute_metadata_api_bind = node['openstack']['bind_service']['all']['compute-metadata-api']
compute_metadata_api_bind_address = bind_address compute_metadata_api_bind
ec2_api_bind = node['openstack']['bind_service']['all']['compute-ec2-api']
ec2_api_bind_address = bind_address ec2_api_bind
ec2_public_endpoint = public_endpoint 'compute-ec2-api'
serial_console_bind = node['openstack']['bind_service']['all']['compute-serial-console']
serial_console_bind_address = bind_address serial_console_bind
serial_proxy_endpoint = public_endpoint 'compute-serial-proxy'
network_endpoint = internal_endpoint 'network'
image_endpoint = internal_endpoint 'image_api'

Chef::Log.debug("openstack-compute::nova-common:identity_public_endpoint|#{identity_endpoint}")
Chef::Log.debug("openstack-compute::nova-common:xvpvnc_endpoint|#{xvpvnc_endpoint}")
Chef::Log.debug("openstack-compute::nova-common:novnc_endpoint|#{novnc_endpoint}")
Chef::Log.debug("openstack-compute::nova-common:compute_api_endpoint|#{::URI.decode compute_api_endpoint.to_s}")
Chef::Log.debug("openstack-compute::nova-common:ec2_public_endpoint|#{ec2_public_endpoint}")
Chef::Log.debug("openstack-compute::nova-common:network_endpoint|#{network_endpoint}")
Chef::Log.debug("openstack-compute::nova-common:image_endpoint|#{image_endpoint}")
# Chef::Log.debug("openstack-compute::nova-common:ironic_endpoint|#{ironic_endpoint}")

if node['openstack']['compute']['conf']['neutron']['auth_plugin'] == 'v2password'
  node.default['openstack']['compute']['conf_secrets']
  .[]('neutron')['password'] =
    get_password 'service', 'openstack-network'
end

node.default['openstack']['compute']['conf_secrets']
.[]('neutron')['metadata_proxy_shared_secret'] =
  get_password 'token', 'neutron_metadata_secret'

if node['openstack']['compute']['driver'].split('.').first == 'vmwareapi'
  node.default['openstack']['compute']['conf_secrets']
    .[]('vmware')['host_password'] =
    get_password 'token', 'openstack_vmware_secret_name'
end

auth_url = auth_uri_transform identity_endpoint.to_s, node['openstack']['compute']['api']['auth']['version']
node.default['openstack']['compute']['conf_secrets']
  .[]('keystone_authtoken')['password'] =
  get_password 'service', 'openstack-compute'

node.default['openstack']['compute']['conf'].tap do |conf|
  conf['DEFAULT']['ec2_listen'] = ec2_api_bind_address
  conf['DEFAULT']['ec2_listen_port'] = ec2_api_bind.port
  conf['DEFAULT']['keystone_ec2_url'] = "#{identity_endpoint.scheme}://#{identity_endpoint.host}:#{identity_endpoint.port}/v2.0/ec2tokens"
  conf['DEFAULT']['iscsi_helper'] = platform_options['iscsi_helper']
  # conf['DEFAULT']['scheduler_default_filters'] = node['openstack']['compute']['scheduler']['default_filters'].join(',')

  if node['openstack']['compute']['conf']['DEFAULT']['enabled_apis'].include?('osapi_compute')
    conf['DEFAULT']['osapi_compute_listen'] = compute_api_bind_address
    conf['DEFAULT']['osapi_compute_listen_port'] = compute_api_bind.port
  end
  # if node['openstack']['mq']['compute']['rabbit']['ha']
  #   conf['DEFAULT']['rabbit_hosts'] = rabbit_hosts
  # end
  conf['DEFAULT']['metadata_listen'] = compute_metadata_api_bind_address
  conf['DEFAULT']['metadata_listen_port'] = compute_metadata_api_bind.port
  conf['vnc']['novncproxy_base_url'] = novnc_endpoint.to_s
  conf['vnc']['xvpvncproxy_base_url'] = xvpvnc_endpoint.to_s
  conf['vnc']['xvpvncproxy_host'] = xvpvnc_bind_address
  conf['vnc']['xvpvncproxy_port'] = xvpvnc_bind.port
  conf['vnc']['novncproxy_host'] = novnc_bind_address
  conf['vnc']['novncproxy_port'] = novnc_bind.port
  conf['vnc']['vncserver_listen'] = vnc_bind_address
  conf['vnc']['vncserver_proxyclient_address'] = vnc_proxy_bind_address
  unless memcache_servers.empty?
    conf['DEFAULT']['memcached_servers'] = memcache_servers
  end

  # [keystone_authtoken] section
  conf['keystone_authtoken']['auth_url'] = auth_url

  # [glance] section
  conf['glance']['api_servers'] =
    "#{image_endpoint.scheme}://#{image_endpoint.host}:#{image_endpoint.port}"

  # [neutron] section
  conf['neutron']['url'] =
    "#{network_endpoint.scheme}://#{network_endpoint.host}:#{network_endpoint.port}"
  conf['neutron']['auth_url'] = identity_endpoint.to_s

  # [serial_console] section
  conf['serial_console']['base_url'] = "#{serial_proxy_endpoint.scheme}://#{serial_proxy_endpoint.host}:#{serial_proxy_endpoint.port}"
  conf['serial_console']['proxyclient_address'] = serial_console_bind_address
end

# merge all config options and secrets to be used in the nova.conf.erb
nova_conf_options = merge_config_options 'compute'

template '/etc/nova/nova.conf' do
  source 'nova.conf.erb'
  owner node['openstack']['compute']['user']
  group node['openstack']['compute']['group']
  mode 00640
  variables(
    # TODO(jaypipes): No support here for >1 image API servers
    # with the glance_api_servers configuration option...
    service_config: nova_conf_options
  )
end

# delete all secrets saved in the attribute
# node['openstack']['compute']['conf_secrets'] after creating the neutron.conf
ruby_block "delete all attributes in node['openstack']['compute']['conf_secrets']" do
  block do
    node.rm(:openstack, :compute, :conf_secrets)
  end
end

template '/etc/nova/rootwrap.conf' do
  source 'rootwrap.conf.erb'
  # Must be root!
  owner 'root'
  group 'root'
  mode 00644
end

execute 'enable nova login' do
  command "usermod -s /bin/sh #{node['openstack']['compute']['user']}"
end
