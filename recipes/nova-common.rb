#
# Cookbook:: openstack-compute
# Recipe:: nova-common
#
# Copyright:: 2012, Rackspace US, Inc.
# Copyright:: 2013, Craig Tracey <craigtracey@gmail.com>
# Copyright:: 2014, SUSE Linux, GmbH.
# Copyright:: 2019-2020, Oregon State University
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

# Make Openstack object available in Chef::Recipe
class ::Chef::Recipe
  include ::Openstack
end

include_recipe 'openstack-common::logging' if node['openstack']['compute']['syslog']['use']

platform_options = node['openstack']['compute']['platform']

package platform_options['common_packages'] do
  options platform_options['package_overrides']
  action :upgrade
end

db_type = node['openstack']['db']['compute']['service_type']
package node['openstack']['db']['python_packages'][db_type] do
  options platform_options['package_overrides']
  action :upgrade
end

# required to run more than one consoleauth process
package platform_options['memcache_python_packages'] do
  options platform_options['package_overrides']
  action :upgrade
end

directory '/etc/nova' do
  owner node['openstack']['compute']['user']
  group node['openstack']['compute']['group']
  mode '750'
  action :create
end

directory node['openstack']['compute']['conf']['DEFAULT']['state_path'] do
  owner node['openstack']['compute']['user']
  group node['openstack']['compute']['group']
  mode '755'
  recursive true
end

directory node['openstack']['compute']['conf']['oslo_concurrency']['lock_path'] do
  owner node['openstack']['compute']['user']
  group node['openstack']['compute']['group']
  mode '755'
  recursive true
end

db_user = node['openstack']['db']['compute']['username']
api_db_user = node['openstack']['db']['compute_api']['username']
db_pass = get_password 'db', 'nova'
api_db_pass = get_password 'db', 'nova_api'

node.default['openstack']['compute']['conf_secrets']
  .[]('database')['connection'] =
  db_uri('compute', db_user, db_pass)
node.default['openstack']['compute']['conf_secrets']
  .[]('api_database')['connection'] =
  db_uri('compute_api', api_db_user, api_db_pass)
if node['openstack']['endpoints']['db']['enabled_slave']
  node.default['openstack']['compute']['conf_secrets']
    .[]('database')['slave_connection'] =
    db_uri('compute', db_user, db_pass, true)
  node.default['openstack']['compute']['conf_secrets']
    .[]('api_database')['slave_connection'] =
    db_uri('compute_api', api_db_user, api_db_pass, true)
end

if node['openstack']['mq']['service_type'] == 'rabbit'
  node.default['openstack']['compute']['conf_secrets']['DEFAULT']['transport_url'] = rabbit_transport_url 'compute'
end

memcache_servers = memcached_servers.join ','

# find the node attribute endpoint settings for the server holding a given role
# Note that the bind and vnc endpoints don't have possible different values for
# internal/public. We'll stick with the general endpoint routine
# for those.
identity_endpoint = internal_endpoint 'identity'
novnc_endpoint = public_endpoint 'compute-novnc'
novnc_bind = node['openstack']['bind_service']['all']['compute-novnc']
novnc_bind_address = bind_address novnc_bind
vnc_bind = node['openstack']['bind_service']['all']['compute-vnc']
vnc_bind_address = bind_address vnc_bind
vnc_proxy_bind = node['openstack']['bind_service']['all']['compute-vnc-proxy']
vnc_proxy_bind_address = bind_address vnc_proxy_bind
compute_api_endpoint = internal_endpoint 'compute-api'
compute_metadata_api_bind = node['openstack']['bind_service']['all']['compute-metadata-api']
compute_metadata_api_bind_address = bind_address compute_metadata_api_bind
serial_console_bind = node['openstack']['bind_service']['all']['compute-serial-console']
serial_console_bind_address = bind_address serial_console_bind
serial_proxy_endpoint = public_endpoint 'compute-serial-proxy'
network_endpoint = internal_endpoint 'network'
image_endpoint = internal_endpoint 'image_api'

Chef::Log.debug("openstack-compute::nova-common:identity_endpoint|#{identity_endpoint}")
Chef::Log.debug("openstack-compute::nova-common:novnc_endpoint|#{novnc_endpoint}")
Chef::Log.debug("openstack-compute::nova-common:compute_api_endpoint|#{compute_api_endpoint}")
Chef::Log.debug("openstack-compute::nova-common:network_endpoint|#{network_endpoint}")
Chef::Log.debug("openstack-compute::nova-common:image_endpoint|#{image_endpoint}")
# Chef::Log.debug("openstack-compute::nova-common:ironic_endpoint|#{ironic_endpoint}")

if node['openstack']['compute']['conf']['neutron']['auth_type'] == 'v3password'
  node.default['openstack']['compute']['conf_secrets']
  .[]('neutron')['password'] =
    get_password 'service', 'openstack-network'
end

node.default['openstack']['compute']['conf_secrets']
.[]('neutron')['metadata_proxy_shared_secret'] =
  get_password 'token', 'neutron_metadata_secret'

auth_url = identity_endpoint.to_s
node.default['openstack']['compute']['conf_secrets']
  .[]('keystone_authtoken')['password'] =
  get_password 'service', 'openstack-compute'

node.default['openstack']['compute']['conf_secrets']
  .[]('service_user')['password'] =
  get_password 'service', 'openstack-compute'

node.default['openstack']['compute']['conf_secrets']
  .[]('placement')['password'] =
  get_password 'service', 'openstack-placement'

node.default['openstack']['compute']['conf'].tap do |conf|
  conf['DEFAULT']['iscsi_helper'] = platform_options['iscsi_helper']

  conf['DEFAULT']['metadata_listen'] = compute_metadata_api_bind_address
  conf['DEFAULT']['metadata_listen_port'] = compute_metadata_api_bind['port']
  conf['vnc']['novncproxy_base_url'] = novnc_endpoint.to_s
  conf['vnc']['novncproxy_host'] = novnc_bind_address
  conf['vnc']['novncproxy_port'] = novnc_bind['port']
  conf['vnc']['server_listen'] = vnc_bind_address
  conf['vnc']['server_proxyclient_address'] = vnc_proxy_bind_address
  unless memcache_servers.empty?
    # Need to set the backend explicitly, see LP bug #1572062
    conf['cache']['backend'] = 'oslo_cache.memcache_pool'
    conf['cache']['enabled'] = 'true'
    conf['cache']['memcache_servers'] = memcache_servers
    # keystonemiddleware needs its own key for this
    conf['keystone_authtoken']['memcached_servers'] = memcache_servers
  end

  # [keystone_authtoken] section
  conf['keystone_authtoken']['auth_url'] = auth_url
  conf['keystone_authtoken']['www_authenticate_uri'] = auth_url

  # [service_user] section
  conf['service_user']['auth_url'] = auth_url

  # [placement] section
  conf['placement']['auth_url'] = auth_url

  # [glance] section
  conf['glance']['api_servers'] =
    "#{image_endpoint.scheme}://#{image_endpoint.host}:#{image_endpoint.port}"

  # [neutron] section
  conf['neutron']['auth_url'] = identity_endpoint.to_s

  # [serial_console] section
  conf['serial_console']['base_url'] = "#{serial_proxy_endpoint.scheme}://#{serial_proxy_endpoint.host}:#{serial_proxy_endpoint.port}"
  conf['serial_console']['proxyclient_address'] = serial_console_bind_address
end

# merge all config options and secrets to be used in nova.conf
nova_conf_options = merge_config_options 'compute'

template '/etc/nova/nova.conf' do
  source 'openstack-service.conf.erb'
  cookbook 'openstack-common'
  owner node['openstack']['compute']['user']
  group node['openstack']['compute']['group']
  mode '640'
  sensitive true
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
  mode '644'
end

user node['openstack']['compute']['user'] do
  shell '/bin/sh'
  action :modify
end
