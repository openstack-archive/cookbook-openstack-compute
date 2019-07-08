# encoding: UTF-8
#
# Cookbook Name:: openstack-compute
# Recipe:: api-metadata
#
# Copyright 2012, Rackspace US, Inc.
# Copyright 2013, Craig Tracey <craigtracey@gmail.com>
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

require 'uri'

class ::Chef::Recipe
  include ::Openstack
end

execute 'nova-metadata: set-selinux-permissive' do
  command '/sbin/setenforce Permissive'
  action :run

  only_if "[ ! -e /etc/httpd/conf/httpd.conf ] && [ -e /etc/redhat-release ] && [ $(/sbin/sestatus | grep -c '^Current mode:.*enforcing') -eq 1 ]"
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
  notifies :run, 'execute[Clear nova-metadata apache restart]', :immediately
end

service 'nova-api-metadata' do
  service_name platform_options['compute_api_metadata_service']
  supports status: true, restart: true
  action [:disable, :stop]
end

bind_service = node['openstack']['bind_service']['all']['compute-metadata-api']

web_app 'nova-metadata' do
  template 'wsgi-template.conf.erb'
  daemon_process 'nova-metadata'
  server_host bind_service['host']
  server_port bind_service['port']
  server_entry '/usr/bin/nova-metadata-wsgi'
  log_dir node['apache']['log_dir']
  run_dir node['apache']['run_dir']
  user node['openstack']['compute']['user']
  group node['openstack']['compute']['group']
  use_ssl node['openstack']['compute']['metadata']['ssl']['enabled']
  cert_file node['openstack']['compute']['metadata']['ssl']['certfile']
  chain_file node['openstack']['compute']['metadata']['ssl']['chainfile']
  key_file node['openstack']['compute']['metadata']['ssl']['keyfile']
  ca_certs_path node['openstack']['compute']['metadata']['ssl']['ca_certs_path']
  cert_required node['openstack']['compute']['metadata']['ssl']['cert_required']
  protocol node['openstack']['compute']['metadata']['ssl']['protocol']
  ciphers node['openstack']['compute']['metadata']['ssl']['ciphers']
end

# Hack until Apache cookbook has lwrp's for proper use of notify restart
# apache2 after keystone if completely configured. Whenever a nova
# config is updated, have it notify the resource which clears the lock
# so the service can be restarted.
# TODO(ramereth): This should be removed once this cookbook is updated
# to use the newer apache2 cookbook which uses proper resources.
edit_resource(:template, "#{node['apache']['dir']}/sites-available/nova-metadata.conf") do
  notifies :run, 'execute[Clear nova-metadata apache restart]', :immediately
end

execute 'nova-metadata apache restart' do
  command "touch #{Chef::Config[:file_cache_path]}/nova-metadata-apache-restarted"
  creates "#{Chef::Config[:file_cache_path]}/nova-metadata-apache-restarted"
  notifies :run, 'execute[nova-metadata: restore-selinux-context]', :immediately
  notifies :restart, 'service[apache2]', :immediately
end

execute 'nova-metadata: restore-selinux-context' do
  command 'restorecon -Rv /etc/httpd /etc/pki || :'
  action :nothing
  only_if { platform_family?('rhel') }
end
