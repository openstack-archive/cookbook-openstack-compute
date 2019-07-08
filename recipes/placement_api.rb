# encoding: UTF-8
#
# Cookbook Name:: openstack-compute
# Recipe:: placement-api
#
# Copyright 2017, OpenStack Foundation
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
end

include_recipe 'openstack-compute::nova-common'

# Create valid apache site configuration file before installing package
bind_service = node['openstack']['bind_service']['all']['placement-api']

web_app 'nova-placement-api' do
  template 'wsgi-template.conf.erb'
  daemon_process 'placement-api'
  server_host bind_service['host']
  server_port bind_service['port']
  server_entry '/usr/bin/nova-placement-api'
  log_dir node['apache']['log_dir']
  run_dir node['apache']['run_dir']
  user node['openstack']['compute']['user']
  group node['openstack']['compute']['group']
  use_ssl node['openstack']['compute']['placement']['ssl']['enabled']
  cert_file node['openstack']['compute']['placement']['ssl']['certfile']
  chain_file node['openstack']['compute']['placement']['ssl']['chainfile']
  key_file node['openstack']['compute']['placement']['ssl']['keyfile']
  ca_certs_path node['openstack']['compute']['placement']['ssl']['ca_certs_path']
  cert_required node['openstack']['compute']['placement']['ssl']['cert_required']
  protocol node['openstack']['compute']['placement']['ssl']['protocol']
  ciphers node['openstack']['compute']['placement']['ssl']['ciphers']
end

platform_options = node['openstack']['compute']['platform']

platform_options['api_placement_packages'].each do |pkg|
  package pkg do
    options platform_options['package_overrides']
    action :upgrade
  end
end

service 'disable nova-placement-api service' do
  service_name platform_options['api_placement_service']
  supports status: true, restart: true
  action [:disable, :stop]
end

nova_user = node['openstack']['compute']['user']
nova_group = node['openstack']['compute']['group']
execute 'placement-api: nova-manage api_db sync' do
  timeout node['openstack']['compute']['dbsync_timeout']
  user nova_user
  group nova_group
  command 'nova-manage api_db sync'
  action :run
end

# Hack until Apache cookbook has lwrp's for proper use of notify restart
# apache2 after keystone if completely configured. Whenever a nova
# config is updated, have it notify the resource which clears the lock
# so the service can be restarted.
# TODO(ramereth): This should be removed once this cookbook is updated
# to use the newer apache2 cookbook which uses proper resources.
edit_resource(:template, "#{node['apache']['dir']}/sites-available/nova-placement-api.conf") do
  notifies :run, 'execute[Clear nova-placement-api apache restart]', :immediately
end

execute 'nova-placement-api apache restart' do
  command "touch #{Chef::Config[:file_cache_path]}/nova-placement-api-apache-restarted"
  creates "#{Chef::Config[:file_cache_path]}/nova-placement-api-apache-restarted"
  notifies :restart, 'service[apache2]', :immediately
end
