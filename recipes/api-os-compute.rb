# encoding: UTF-8
#
# Cookbook Name:: openstack-compute
# Recipe:: api-os-compute
#
# Copyright 2012, Rackspace US, Inc.
# Copyright 2018, Workday, Inc.
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

execute 'nova-api: set-selinux-permissive' do
  command '/sbin/setenforce Permissive'
  action :run

  only_if "[ ! -e /etc/httpd/conf/httpd.conf ] && [ -e /etc/redhat-release ] && [ $(/sbin/sestatus | grep -c '^Current mode:.*enforcing') -eq 1 ]"
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
  notifies :run, 'execute[Clear nova-api apache restart]', :immediately
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

web_app 'nova-api' do
  template 'wsgi-template.conf.erb'
  daemon_process 'nova-api'
  server_host bind_service['host']
  server_port bind_service['port']
  server_entry '/usr/bin/nova-api-wsgi'
  log_dir node['apache']['log_dir']
  run_dir node['apache']['run_dir']
  user node['openstack']['compute']['user']
  group node['openstack']['compute']['group']
  use_ssl node['openstack']['compute']['api']['ssl']['enabled']
  cert_file node['openstack']['compute']['api']['ssl']['certfile']
  chain_file node['openstack']['compute']['api']['ssl']['chainfile']
  key_file node['openstack']['compute']['api']['ssl']['keyfile']
  ca_certs_path node['openstack']['compute']['api']['ssl']['ca_certs_path']
  cert_required node['openstack']['compute']['api']['ssl']['cert_required']
  protocol node['openstack']['compute']['api']['ssl']['protocol']
  ciphers node['openstack']['compute']['api']['ssl']['ciphers']
end

include_recipe 'openstack-compute::_nova_cell'

# Hack until Apache cookbook has lwrp's for proper use of notify restart
# apache2 after keystone if completely configured. Whenever a nova
# config is updated, have it notify the resource which clears the lock
# so the service can be restarted.
# TODO(ramereth): This should be removed once this cookbook is updated
# to use the newer apache2 cookbook which uses proper resources.
edit_resource(:template, "#{node['apache']['dir']}/sites-available/nova-api.conf") do
  notifies :run, 'execute[Clear nova-api apache restart]', :immediately
end

execute 'nova-api apache restart' do
  command "touch #{Chef::Config[:file_cache_path]}/nova-api-apache-restarted"
  creates "#{Chef::Config[:file_cache_path]}/nova-api-apache-restarted"
  notifies :run, 'execute[nova-api: restore-selinux-context]', :immediately
  notifies :restart, 'service[apache2]', :immediately
end

execute 'nova-api: restore-selinux-context' do
  command 'restorecon -Rv /etc/httpd /etc/pki || :'
  action :nothing
  only_if { platform_family?('rhel') }
end
