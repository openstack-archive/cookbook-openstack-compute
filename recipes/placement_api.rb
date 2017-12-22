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

platform_options = node['openstack']['compute']['platform']

platform_options['api_placement_packages'].each do |pkg|
  package pkg do
    options platform_options['package_overrides']
    action :upgrade
  end
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

service 'disable nova-placement-api service' do
  service_name platform_options['api_placement_service']
  supports status: true, restart: true
  action [:disable, :stop]
end

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
  use_ssl node['openstack']['placement']['ssl']['enabled']
  cert_file node['openstack']['placement']['ssl']['certfile']
  chain_file node['openstack']['placement']['ssl']['chainfile']
  key_file node['openstack']['placement']['ssl']['keyfile']
  ca_certs_path node['openstack']['placement']['ssl']['ca_certs_path']
  cert_required node['openstack']['placement']['ssl']['cert_required']
  protocol node['openstack']['placement']['ssl']['protocol']
  ciphers node['openstack']['placement']['ssl']['ciphers']
end
