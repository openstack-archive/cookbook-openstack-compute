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

class ::Chef::Recipe # rubocop:disable Documentation
  include ::Openstack
end

include_recipe 'openstack-compute::nova-common'

platform_options = node['openstack']['compute']['platform']

directory ::File.dirname(node['openstack']['compute']['api']['auth']['cache_dir']) do
  owner node['openstack']['compute']['user']
  group node['openstack']['compute']['group']
  mode 00700
end

# NOTE(mrodden): required for keystone auth middleware
package 'python-keystoneclient' do
  action :upgrade
end

platform_options['api_os_compute_packages'].each do |pkg|
  package pkg do
    options platform_options['package_overrides']

    action :upgrade
  end
end

service 'nova-api-os-compute' do
  service_name platform_options['api_os_compute_service']
  supports status: true, restart: true
  subscribes :restart, resources('template[/etc/nova/nova.conf]')

  action [:enable, :start]
end

template '/etc/nova/api-paste.ini' do
  source 'api-paste.ini.erb'
  owner node['openstack']['compute']['user']
  group node['openstack']['compute']['group']
  mode 00644
  notifies :restart, 'service[nova-api-os-compute]'
end
