# encoding: UTF-8
#
# Cookbook Name:: openstack-compute
# Recipe:: api-os-compute
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

class ::Chef::Recipe
  include ::Openstack
end

include_recipe 'openstack-compute::nova-common'

platform_options = node['openstack']['compute']['platform']

platform_options['api_os_compute_packages'].each do |pkg|
  package pkg do
    options platform_options['package_overrides']
    action :upgrade
  end
end

nova_user = node['openstack']['compute']['user']
nova_group = node['openstack']['compute']['group']

template '/etc/nova/api-paste.ini' do
  source 'api-paste.ini.erb'
  owner nova_user
  group nova_group
  mode 0o0644
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
  action [:enable, :start]
  subscribes :restart, [
    'template[/etc/nova/nova.conf]',
    'template[/etc/nova/api-paste.ini]',
  ]
end

include_recipe 'openstack-compute::_nova_cell'
