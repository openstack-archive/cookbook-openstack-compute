# encoding: UTF-8
#
# Cookbook:: openstack-compute
# Recipe:: api-os-compute
#
# Copyright:: 2012, Rackspace US, Inc.
# Copyright:: 2018, Workday, Inc.
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

include_recipe 'openstack-compute::nova-common'

platform_options = node['openstack']['compute']['platform']

package platform_options['api_os_compute_packages'] do
  options platform_options['package_overrides']
  action :upgrade
end

nova_user = node['openstack']['compute']['user']
nova_group = node['openstack']['compute']['group']

template '/etc/nova/api-paste.ini' do
  source 'api-paste.ini.erb'
  owner nova_user
  group nova_group
  mode '644'
  notifies :restart, 'service[apache2]'
end

execute 'nova-manage api_db sync' do
  timeout node['openstack']['compute']['dbsync_timeout']
  user nova_user
  group nova_group
  command 'nova-manage api_db sync'
  action :run
end

service 'nova-api-os-compute' do
  service_name platform_options['api_os_compute_service']
  supports status: true, restart: true
  action [:disable, :stop]
end

bind_service = node['openstack']['bind_service']['all']['compute-api']

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
apache2_module 'ssl' if node['openstack']['compute']['api']['ssl']['enabled']

template "#{apache_dir}/sites-available/nova-api.conf" do
  extend Apache2::Cookbook::Helpers
  source 'wsgi-template.conf.erb'
  variables(
    daemon_process: 'nova-api',
    server_host: bind_service['host'],
    server_port: bind_service['port'],
    server_entry: '/usr/bin/nova-api-wsgi',
    log_dir: default_log_dir,
    run_dir: lock_dir,
    user: node['openstack']['compute']['user'],
    group: node['openstack']['compute']['group'],
    use_ssl: node['openstack']['compute']['api']['ssl']['enabled'],
    cert_file: node['openstack']['compute']['api']['ssl']['certfile'],
    chain_file: node['openstack']['compute']['api']['ssl']['chainfile'],
    key_file: node['openstack']['compute']['api']['ssl']['keyfile'],
    ca_certs_path: node['openstack']['compute']['api']['ssl']['ca_certs_path'],
    cert_required: node['openstack']['compute']['api']['ssl']['cert_required'],
    protocol: node['openstack']['compute']['api']['ssl']['protocol'],
    ciphers: node['openstack']['compute']['api']['ssl']['ciphers']
  )
  notifies :restart, 'service[apache2]'
end

apache2_site 'nova-api' do
  notifies :restart, 'service[apache2]', :immediately
end

include_recipe 'openstack-compute::_nova_cell'
