#
# Cookbook Name:: nova
# Recipe:: ceilometer-common
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
require "uri"

class ::Chef::Recipe
  include ::Openstack
end

include_recipe "nova::nova-common"
include_recipe "python::pip"
if node["ceilometer"]["syslog"]["use"]
  include_recipe "openstack-common::logging"
end

ceilometer_conf = node["nova"]["ceilometer"]["conf"]

dependent_pkgs = node["nova"]["ceilometer"]["dependent_pkgs"]
dependent_pkgs.each do |pkg|
  package pkg do
    action :upgrade
  end
end

#  Cleanup old installation
python_pip "ceilometer" do
  action :remove
end

bin_names = ['agent-compute', 'agent-central', 'collector', 'dbsync', 'api']
bin_names.each do |bin_name|
  file "ceilometer-#{bin_name}" do
    action :delete
  end
end

# install source
install_dir = node["nova"]["ceilometer"]["install_dir"]

nova_owner = node["nova"]["user"]
nova_group = node["nova"]["group"]

directory install_dir do
  owner nova_owner
  group nova_group
  mode  00755
  recursive true

  action :create
end

git_branch = node["nova"]["ceilometer"]["branch"]
git_repo = node["nova"]["ceilometer"]["repo"]
git install_dir do
  repo git_repo
  reference git_branch
  action :sync
end

python_pip install_dir do
  action :install
end

directory ::File.dirname(ceilometer_conf) do
  owner nova_owner
  group nova_group
  mode  00755

  action :create
end

rabbit_server_role = node["nova"]["rabbit_server_chef_role"]
rabbit_info = config_by_role rabbit_server_role, "queue"
rabbit_port = rabbit_info["port"]
rabbit_ipaddress = rabbit_info["host"]
rabbit_user = node["nova"]["rabbit"]["username"]
rabbit_pass = user_password "rabbit"
rabbit_vhost = node["nova"]["rabbit"]["vhost"]

# nova db
nova_db_user = node['nova']['db']['username']
nova_db_pass = db_password "nova"
nova_uri = db_uri("compute", nova_db_user, nova_db_pass)

# ceilometer db
ceilo_db_info = db 'metering'
ceilo_db_user = node['nova']['ceilometer']['db']['username']
ceilo_db_pass = db_password "ceilometer"
ceilo_db_query = ceilo_db_info['db_type'] == 'mysql' ? '?charset=utf8' : nil
ceilo_db_uri = db_uri("metering", ceilo_db_user, ceilo_db_pass).to_s + ceilo_db_query

service_user = node["nova"]["service_user"]
service_pass = service_password "nova"
service_tenant = node["nova"]["service_tenant_name"]

# find the node attribute endpoint settings for the server holding a given role
identity_admin_endpoint = endpoint "identity-admin"
auth_uri = ::URI.decode identity_admin_endpoint.to_s

image_endpoint = endpoint "image-api"

Chef::Log.debug("nova::ceilometer-common:rabbit_info|#{rabbit_info}")
Chef::Log.debug("nova::ceilometer-common:service_user|#{service_user}")
Chef::Log.debug("nova::ceilometer-common:service_tenant|#{service_tenant}")
Chef::Log.debug("nova::ceilometer-common:identity_admin_endpoint|#{identity_admin_endpoint.to_s}")

template ceilometer_conf do
  source "ceilometer.conf.erb"
  owner  nova_owner
  group  nova_group
  mode   00644
  variables(
    :auth_uri => auth_uri,
    :database_connection => ceilo_db_uri,
    :image_endpoint_host => image_endpoint.host,
    :identity_endpoint => identity_admin_endpoint,
    :rabbit_ipaddress => rabbit_ipaddress,
    :rabbit_pass => rabbit_pass,
    :rabbit_port => rabbit_port,
    :rabbit_user => rabbit_user,
    :rabbit_vhost => rabbit_vhost,
    :service_pass => service_pass,
    :service_tenant_name => service_tenant,
    :service_user => service_user,
    :sql_connection => nova_uri 
  )
end

cookbook_file "/etc/ceilometer/policy.json" do
  source "policy.json"
  mode 0755
  owner nova_owner
  group nova_group
end
