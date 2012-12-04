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

class ::Chef::Recipe
  include ::Openstack
end

include_recipe "mongodb"
include_recipe "nova::nova-common"
include_recipe "python::pip"

api_logdir = '/var/log/ceilometer-api'
nova_owner = node["nova"]["user"]
nova_group = node["nova"]["group"]

directory api_logdir do
  owner nova_owner
  group nova_group
  mode  00755

  action :create
end

python_pip "ceilometer" do
  action :install
end

directory "/etc/ceilometer" do
  owner nova_owner
  group nova_group
  mode  00755

  action :create
end

rabbit_server_role = node["nova"]["rabbit_server_chef_role"]
rabbit_info = config_by_role rabbit_server_role, "queue"

nova_setup_role = node["nova"]["nova_setup_chef_role"]
nova_setup_info = config_by_role nova_setup_role, "nova"

db_user = node['nova']['db']['username']
db_pass = db_password "nova"
sql_connection = db_uri("compute", db_user, db_pass)

keystone_service_role = node["nova"]["keystone_service_chef_role"]
keystone = config_by_role keystone_service_role, "keystone"

# find the node attribute endpoint settings for the server holding a given role
identity_admin_endpoint = endpoint "identity-admin"

Chef::Log.debug("nova::ceilometer-common:rabbit_info|#{rabbit_info}")
Chef::Log.debug("nova::ceilometer-common:keystone|#{keystone}")
Chef::Log.debug("nova::ceilometer-common:identity_admin_endpoint|#{identity_admin_endpoint.to_s}")

template "/etc/ceilometer/ceilometer.conf" do
  source "ceilometer.conf.erb"
  owner  nova_owner
  group  nova_group
  mode   00644
  variables(
    :sql_connection => sql_connection,
    :rabbit_ipaddress => rabbit_info["host"],
    :rabbit_port => rabbit_info["port"],
    :user => keystone["admin_user"],
    :tenant => keystone["users"][keystone["admin_user"]]["default_tenant"],
    :password => keystone["users"][keystone["admin_user"]]["password"],
    :identity_admin_endpoint => identity_admin_endpoint
  )
end

cookbook_file "/etc/ceilometer/policy.json" do
  source "policy.json"
  mode 0755
  owner nova_owner
  group nova_group
end
