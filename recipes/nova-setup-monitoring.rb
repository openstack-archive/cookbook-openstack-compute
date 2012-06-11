#
# Cookbook Name:: nova
# Recipe:: nova-setup-monitoring
#
# Copyright 2009, Rackspace Hosting, Inc.
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

# We'll intentionally split the monitoring recipe from the stock
# nova recipe, in case there are other monitoring systems besides
# collectd that people want to integrate.

########################################
# BEGIN COLLECTD SECTION
# Allow for enable/disable of monit
if node["enable_collectd"]
  include_recipe "collectd-graphite::collectd-client"

  ks_service_endpoint = get_access_endpoint("keystone", "keystone","service-api")
  keystone = get_settings_by_roles("keystone", "keystone")
  keystone_admin_user = keystone["admin_user"]
  keystone_admin_password = keystone["users"][keystone_admin_user]["password"]
  keystone_admin_tenant = keystone["users"][keystone_admin_user]["default_tenant"]
  mysql_info = get_settings_by_role("mysql-master", "mysql")

  # run through each role and find the db usernames and passwords
  db_options = {}
  rolemap = {
    "keystone" => "keystone",
    "glance-registry" => "glance",
    "horizon-server" => "horizon",
    "nova-setup" => "nova"
  }

  rolemap.each_pair do |role, key|
    attrs = get_settings_by_role(role, key)
    if attrs
      db_options[attrs["db"]["name"]] = {
        :host => mysql_info["bind_address"],
        :user => attrs["db"]["username"],
        :password => attrs["db"]["password"],
        :master_stats => false
      }
    end
  end

  collectd_plugin "mysql" do
    template "collectd-plugin-mysql.conf.erb"
    cookbook "nova"
    options :databases => db_options
  end

  cookbook_file File.join(node['collectd']['plugin_dir'], "nova_plugin.py") do
    source "nova_plugin.py"
    owner "root"
    group "root"
    mode "0644"
  end

  collectd_python_plugin "nova_plugin" do
    options(
      "Username"=>keystone_admin_user,
      "Password"=>keystone_admin_password,
      "TenantName"=>keystone_admin_tenant,
      "AuthURL"=>ks_service_endpoint["uri"]
    )
  end
end
########################################
