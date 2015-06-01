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

class ::Chef::Recipe # rubocop:disable Documentation
  include ::Openstack
end

if node['openstack']['compute']['docker']['enable']
  include_recipe 'openstack-compute::docker-setup'
end

include_recipe 'openstack-compute::nova-common'
if node['openstack']['compute']['enabled_apis'].include?('metadata')
  Chef::Log.warn('Attribute enabled_apis contains metadata, this '\
                 'could result in a timing issue starting the service. '\
                 'Please remove this value and include the api-metadata '\
                 'recipe instead')
end
include_recipe 'openstack-compute::network'

platform_options = node['openstack']['compute']['platform']

platform_options['compute_compute_packages'].each do |pkg|
  package pkg do
    options platform_options['package_overrides']

    action :upgrade
  end
end

virt_type = node['openstack']['compute']['libvirt']['virt_type']

platform_options["#{virt_type}_compute_packages"].each do |pkg|
  package pkg do
    options platform_options['package_overrides']

    action :upgrade
  end
end

# Installing nfs client packages because in grizzly, cinder nfs is supported
# Never had to install iscsi packages because nova-compute package depends it
# So volume-attach 'just worked' before - alop
platform_options['nfs_packages'].each do |pkg|
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

cookbook_file '/etc/nova/nova-compute.conf' do
  source 'nova-compute.conf'
  mode 00644

  action :create
end

directory node['openstack']['compute']['instances_path'] do
  owner node['openstack']['compute']['user']
  group node['openstack']['compute']['group']
  mode 00755
  recursive true
end

include_recipe 'openstack-compute::libvirt'

docker_filter_source_path = node['openstack']['compute']['docker']['filter_source_path']
install_directory  = "#{Chef::Config['file_cache_path']}/nova-docker"
docker_group = node['openstack']['compute']['docker']['group']
docker_group_members = node['openstack']['compute']['service_user']
filter_target_path = docker_filter_source_path + '/docker.filters'
filter_source_path = install_directory + filter_target_path

group docker_group do
  members docker_group_members
  action [:create, :manage]
  only_if { node['openstack']['compute']['docker']['enable'] }
end

file 'docker.filter' do
  owner 'root'
  group 'root'
  mode 00644
  path filter_target_path
  content lazy { ::File.open(filter_source_path).read }
  action :create
  only_if { node['openstack']['compute']['docker']['enable'] }
end

service 'nova-compute' do
  service_name platform_options['compute_compute_service']
  supports status: true, restart: true
  subscribes :restart, resources('template[/etc/nova/nova.conf]')
  subscribes :restart, resources('file[docker.filter]')

  action [:enable, :start]
end
