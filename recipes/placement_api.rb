#
# Cookbook:: openstack-compute
# Recipe:: placement-api
#
# Copyright:: 2017, OpenStack Foundation
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
#

class ::Chef::Recipe
  include ::Openstack
  include Apache2::Cookbook::Helpers
end

include_recipe 'openstack-compute::_nova_apache'
include_recipe 'openstack-compute::_nova_cell'

# Create valid apache site configuration file before installing package
bind_service = node['openstack']['bind_service']['all']['placement-api']
if node['openstack']['compute']['nova_placement']
  placement_user = node['openstack']['compute']['user']
  placement_group = node['openstack']['compute']['group']
  placement_http = 'nova-placement'
  placement_binary = '/usr/bin/nova-placement-api'
  placement_dbsync = 'nova-manage api_db sync'
else
  placement_user = 'placement'
  placement_group = 'placement'
  placement_http = 'placement'
  placement_binary = '/usr/bin/placement-api'
  placement_dbsync = 'placement-manage db sync'
end

platform_options = node['openstack']['compute']['platform']

package platform_options['api_placement_packages'] do
  options platform_options['package_overrides']
  action :upgrade
end

service platform_options['api_placement_service'] do
  supports status: true, restart: true
  action [:disable, :stop]
end

apache2_site 'nova-placement-api' do
  action :disable
  only_if { platform_family?('debian') }
end

unless node['openstack']['compute']['nova_placement']
  db_user = node['openstack']['db']['placement']['username']
  db_pass = get_password 'db', 'placement'
  identity_endpoint = internal_endpoint 'identity'
  auth_url = ::URI.decode identity_endpoint.to_s

  node.default['openstack']['placement']['conf_secrets']
    .[]('placement_database')['connection'] =
    db_uri('placement', db_user, db_pass)
  node.default['openstack']['placement']['conf_secrets']
    .[]('keystone_authtoken')['password'] =
    get_password 'service', 'openstack-placement'
  if node['openstack']['endpoints']['db']['enabled_slave']
    node.default['openstack']['placement']['conf_secrets']
      .[]('placement_database')['slave_connection'] =
      db_uri('placement', db_user, db_pass, true)
  end

  if node['openstack']['mq']['service_type'] == 'rabbit'
    node.default['openstack']['placement']['conf_secrets']['DEFAULT']['transport_url'] = rabbit_transport_url 'placement'
  end

  memcache_servers = memcached_servers.join ','
  placement_api_endpoint = internal_endpoint 'placement-api'
  Chef::Log.debug("openstack-compute::nova-common:placement_api_endpoint|#{::URI.decode placement_api_endpoint.to_s}")

  node.default['openstack']['placement']['conf'].tap do |conf|
    unless memcache_servers.empty?
      # Need to set the backend explicitly, see LP bug #1572062
      conf['cache']['backend'] = 'oslo_cache.memcache_pool'
      conf['cache']['enabled'] = 'true'
      conf['cache']['memcache_servers'] = memcache_servers
    end
    # [keystone_authtoken] section
    conf['keystone_authtoken']['auth_url'] = auth_url
    conf['keystone_authtoken']['www_authenticate_uri'] = auth_url
  end
  # merge all config options and secrets to be used in placement.conf
  placement_conf_options = merge_config_options 'placement'

  template '/etc/placement/placement.conf' do
    source 'openstack-service.conf.erb'
    cookbook 'openstack-common'
    owner placement_user
    group placement_group
    mode '640'
    sensitive true
    variables(
      service_config: placement_conf_options
    )
    notifies :restart, 'service[apache2]'
  end

  # delete all secrets saved in the attribute
  # node['openstack']['placement']['conf_secrets'] after creating the neutron.conf
  ruby_block "delete all attributes in node['openstack']['placement']['conf_secrets']" do
    block do
      node.rm(:openstack, :placement, :conf_secrets)
    end
  end
end

# Finds and appends the listen port to the apache2_install[openstack]
# resource which is defined in openstack-identity::server-apache.
apache_resource = find_resource(:apache2_install, 'openstack')

if apache_resource
  apache_resource.listen = [apache_resource.listen, "#{bind_service['host']}:#{bind_service['port']}"].flatten
else
  apache2_install 'openstack' do
    listen "#{bind_service['host']}:#{bind_service['port']}"
  end
end

apache2_module 'wsgi'
apache2_module 'ssl' if node['openstack']['compute']['placement']['ssl']['enabled']

template "#{apache_dir}/sites-available/#{placement_http}.conf" do
  extend Apache2::Cookbook::Helpers
  source 'wsgi-template.conf.erb'
  variables(
    daemon_process: 'placement-api',
    server_host: bind_service['host'],
    server_port: bind_service['port'],
    server_entry: placement_binary,
    log_dir: default_log_dir,
    run_dir: lock_dir,
    user: placement_user,
    group: placement_group,
    processes: node['openstack']['compute']['placement']['processes'],
    threads: node['openstack']['compute']['placement']['threads'],
    use_ssl: node['openstack']['compute']['placement']['ssl']['enabled'],
    cert_file: node['openstack']['compute']['placement']['ssl']['certfile'],
    chain_file: node['openstack']['compute']['placement']['ssl']['chainfile'],
    key_file: node['openstack']['compute']['placement']['ssl']['keyfile'],
    ca_certs_path: node['openstack']['compute']['placement']['ssl']['ca_certs_path'],
    cert_required: node['openstack']['compute']['placement']['ssl']['cert_required'],
    protocol: node['openstack']['compute']['placement']['ssl']['protocol'],
    ciphers: node['openstack']['compute']['placement']['ssl']['ciphers']
  )
  notifies :restart, 'service[apache2]'
end

apache2_site placement_http do
  notifies :restart, 'service[apache2]', :immediately
end

execute 'placement-api: nova-manage api_db sync' do
  timeout node['openstack']['compute']['dbsync_timeout']
  user placement_user
  group placement_group
  command placement_dbsync
  action :run
end
