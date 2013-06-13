#
# Cookbook Name:: openstack-compute
# Recipe:: ceilometer-api
#
# Copyright 2012, AT&T
# Copyright 2013, Craig Tracey <craigtracey@gmail.com>
# Copyright 2013, SUSE Linux GmbH
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

include_recipe "openstack-compute::ceilometer-common"

compute_owner = node["openstack"]["compute"]["user"]
compute_group = node["openstack"]["compute"]["group"]

directory ::File.dirname(node["openstack"]["compute"]["ceilometer"]["api"]["auth"]["cache_dir"]) do
  owner compute_owner
  group compute_group
  mode 00700
end

include_recipe "apache2"
include_recipe "apache2::mod_proxy"
include_recipe "apache2::mod_proxy_http"

apache_module "proxy"
apache_module "proxy_http"

htpasswd_path     = "#{node["apache"]["dir"]}/htpasswd"
htpasswd_user     = node["openstack"]["compute"]["ceilometer"]["api"]["auth"]["user"]
htpasswd_password = node["openstack"]["compute"]["ceilometer"]["api"]["auth"]["password"]

template node["openstack"]["compute"]["ceilometer"]["api"]["meter-site"] do
  source "meter-site.conf.erb"
  owner  "root"
  group  "root"
  variables(:htpasswd_path => htpasswd_path)
end

apache_site "meter", :enabled => true

file htpasswd_path do
  owner "root"
  group "root"
  mode "0755"
end

execute "add htpasswd file" do
  if node["platform"] == "suse"
    command "/usr/bin/htpasswd2 -b #{htpasswd_path} #{htpasswd_user} #{htpasswd_password}"
  else
    command "/usr/bin/htpasswd -b #{htpasswd_path} #{htpasswd_user} #{htpasswd_password}"
  end
end

service "apache2"
if node["openstack"]["compute"]["platform"]["ceilometer_packages"]
  node["openstack"]["compute"]["platform"]["ceilometer_packages"]["api"].each do |pkg|
    package pkg
  end

  service node["openstack"]["compute"]["platform"]["ceilometer_services"]["api"] do
    action :start
  end
else
  ceilometer_conf = node["openstack"]["compute"]["ceilometer"]["conf"]
  conf_switch = "--config-file #{ceilometer_conf}"

  service "ceilometer-api" do
    service_name "ceilometer-api"
    action [:start]
    start_command "nohup /usr/local/bin/ceilometer-api #{conf_switch} &"
    stop_command "pkill -f ceilometer-api"
  end
end
