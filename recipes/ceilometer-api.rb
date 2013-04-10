#
# Cookbook Name:: nova
# Recipe:: ceilometer-api
#
# Copyright 2012, AT&T
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

include_recipe "nova::ceilometer-common"

nova_owner = node["nova"]["user"]
nova_group = node["nova"]["group"]

directory ::File.dirname(node["nova"]["api"]["auth"]["cache_dir"]) do
  owner node["nova"]["user"]
  group node["nova"]["group"]
  mode 00700

  only_if { node["openstack"]["auth"]["strategy"] == "pki" }
end

bindir = '/usr/local/bin'
ceilometer_conf = node["nova"]["ceilometer"]["conf"]
conf_switch = "--config-file #{ceilometer_conf}"

include_recipe "apache2"
include_recipe "apache2::mod_proxy"
include_recipe "apache2::mod_proxy_http"

apache_module "proxy"
apache_module "proxy_http"

vhost_server_name = node['nova']['ceilometer']['api']['vhost_server_name']
htpasswd_path     = "#{node['apache']['dir']}/htpasswd"
htpasswd_user     = node['nova']['ceilometer']['api']['auth']['user']
htpasswd_password = node['nova']['ceilometer']['api']['auth']['password']

template "#{node['apache']['dir']}/sites-available/meter" do
  source "meter-site.conf.erb"
  owner  'root'
  group  'root'
  variables(:vhost_server_name => vhost_server_name,
            :htpasswd_path => htpasswd_path)
end

apache_site "meter", :enabled => true

file htpasswd_path do
  owner 'root'
  group 'root'
  mode "0755"
end

execute "add htpasswd file" do
  command "/usr/bin/htpasswd -b #{htpasswd_path} #{htpasswd_user} #{htpasswd_password}"
end

service "apache2"

service "ceilometer-api" do
  service_name "ceilometer-api"
  action [:start]
  start_command "nohup #{bindir}/ceilometer-api #{conf_switch} &"
  stop_command "pkill -f ceilometer-api"
end
