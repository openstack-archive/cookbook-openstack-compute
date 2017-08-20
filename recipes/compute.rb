# encoding: UTF-8
#
# Cookbook Name:: openstack-compute
# Recipe:: compute
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

class ::Chef::Recipe
  include ::Openstack
end

include_recipe 'openstack-compute::nova-common'
platform_options = node['openstack']['compute']['platform']

platform_options['compute_compute_packages'].each do |pkg|
  package pkg do
    options platform_options['package_overrides']
    action :upgrade
  end
end

virt_type = node['openstack']['compute']['conf']['libvirt']['virt_type']

platform_options["#{virt_type}_compute_packages"].each do |pkg|
  package pkg do
    options platform_options['package_overrides']
    action :upgrade
  end
end

# More volume attach packages
platform_options['volume_packages'].each do |pkg|
  package pkg do
    options platform_options['package_overrides']
    action :upgrade
  end
end

# TODO: (jklare) this has to be refactored!!!
cookbook_file '/etc/nova/nova-compute.conf' do
  source 'nova-compute.conf'
  mode 0o0644
  action :create
end

directory node['openstack']['compute']['conf']['DEFAULT']['instances_path'] do
  owner node['openstack']['compute']['user']
  group node['openstack']['compute']['group']
  mode 0o0755
  recursive true
end

include_recipe 'openstack-compute::libvirt'

service 'nova-compute' do
  service_name platform_options['compute_compute_service']
  supports status: true, restart: true
  action [:enable, :start]
  subscribes :restart, [
    'template[/etc/nova/nova.conf]',
    'file[docker.filter]',
  ]
end
