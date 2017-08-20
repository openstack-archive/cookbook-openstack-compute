# encoding: UTF-8
#
# Cookbook Name:: openstack-compute
# Recipe:: api-metadata
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

require 'uri'

class ::Chef::Recipe
  include ::Openstack
end

include_recipe 'openstack-compute::nova-common'

platform_options = node['openstack']['compute']['platform']

platform_options['compute_api_metadata_packages'].each do |pkg|
  package pkg do
    options platform_options['package_overrides']
    action :upgrade
  end
end

template '/etc/nova/api-paste.ini' do
  source 'api-paste.ini.erb'
  owner node['openstack']['compute']['user']
  group node['openstack']['compute']['group']
  mode 0o0644
end

service 'nova-api-metadata' do
  service_name platform_options['compute_api_metadata_service']
  supports status: true, restart: true
  action [:enable, :start]
  subscribes :restart, [
    'template[/etc/nova/nova.conf]',
    'template[/etc/nova/api-paste.ini]',
  ]
end
