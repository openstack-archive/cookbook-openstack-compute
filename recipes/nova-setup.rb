#
# Cookbook Name:: nova
# Recipe:: nova-setup
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

include_recipe "nova::nova-common"
include_recipe "mysql::client"

if Chef::Config[:solo]
  Chef::Log.warn("This recipe uses search. Chef Solo does not support search.")
else
  # Lookup mysql ip address
  mysql_server = search(:node, "roles:mysql-master AND chef_environment:#{node.chef_environment}")
  if mysql_server.length > 0
    Chef::Log.info("nova-common/mysql: using search")
    db_ip_address = mysql_server[0]['mysql']['bind_address']
    db_root_password = mysql_server[0]['mysql']['server_root_password']
  else
    Chef::Log.info("nova-common/mysql: NOT using search")
    db_ip_address = node['mysql']['bind_address']
    db_root_password = node['mysql']['server_root_password']
  end
end

connection_info = {:host => db_ip_address, :username => "root", :password => db_root_password}
mysql_database "create nova database" do
  connection connection_info
  database_name node["nova"]["db"]["name"]
  action :create
end

mysql_database_user node["nova"]["db"]["username"] do
  connection connection_info
  password node["nova"]["db"]["password"]
  action :create
end

mysql_database_user node["nova"]["db"]["username"] do
  connection connection_info
  password node["nova"]["db"]["password"]
  database_name node["nova"]["db"]["name"]
  host '%'
  privileges ["all"]
  action :grant
end

execute "nova-manage db sync" do
  command "nova-manage db sync"
  action :run
  not_if "nova-manage db version && test $(nova-manage db version) -gt 0"
end

execute "nova-manage network create --label=public" do
  command "nova-manage network create --multi_host='T' --label=#{node["nova"]["network"]["public"]["label"]} --fixed_range_v4=#{node["nova"]["network"]["public"]["ipv4_cidr"]} --num_networks=#{node["nova"]["network"]["public"]["num_networks"]} --network_size=#{node["nova"]["network"]["public"]["network_size"]} --bridge=#{node["nova"]["network"]["public"]["bridge"]} --bridge_interface=#{node["nova"]["network"]["public"]["bridge_dev"]} --dns1=#{node["nova"]["network"]["public"]["dns1"]} --dns2=#{node["nova"]["network"]["public"]["dns2"]}"
  action :run
  not_if "nova-manage network list | grep #{node["nova"]["network"]["public"]["ipv4_cidr"]}"
end

execute "nova-manage network create --label=private" do
  command "nova-manage network create --multi_host='T' --label=#{node["nova"]["network"]["private"]["label"]} --fixed_range_v4=#{node["nova"]["network"]["private"]["ipv4_cidr"]} --num_networks=#{node["nova"]["network"]["private"]["num_networks"]} --network_size=#{node["nova"]["network"]["private"]["network_size"]} --bridge=#{node["nova"]["network"]["private"]["bridge"]} --bridge_interface=#{node["nova"]["network"]["private"]["bridge_dev"]}"
  action :run
  not_if "nova-manage network list | grep #{node["nova"]["network"]["private"]["ipv4_cidr"]}"
end


if node.has_key?(:floating) and node["nova"]["network"]["floating"].has_key?(:ipv4_cidr)
  execute "nova-manage floating create" do
    command "nova-manage floating create --ip_range=#{node["nova"]["network"]["floating"]["ipv4_cidr"]}"
    action :run
    not_if "nova-manage floating list"
  end
end


