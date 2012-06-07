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

include_recipe "collectd-graphite::collectd-client"

# First, let's monitor mysql

# this gets me credentials, still need per-role info on db name
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
