#
# Cookbook Name:: nova
# Recipe:: common
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

# Distribution specific settings go here
if platform?(%w{fedora})
  # Fedora
  nova_common_package = "openstack-nova"
  nova_common_package_options = ""
  include_recipe "selinux::disabled"
else
  # All Others (right now Debian and Ubuntu)
  nova_common_package = "nova-common"
  nova_common_package_options = "-o Dpkg::Options::='--force-confold' --force-yes"
end

package nova_common_package do
  action :upgrade
  options nova_common_package_options
end

directory "/etc/nova" do
  action :create
  owner :nova
  group :nova
  mode "0755"
  not_if do
    File.exists?("/etc/nova")
  end
end
 
if Chef::Config[:solo]
  Chef::Log.warn("This recipe uses search. Chef Solo does not support search.")
else
  # Lookup mysql ip address
  mysql_server = search(:node, 'role:mysql-server')
  db_ip_address = mysql_server[0]['ipaddress'] 
  # Or
  # db_ipaddress = mysql_server[0]['mysql']['bind_address']

  # Lookup rabbit ip address
  rabbit = search(:node, 'role:rabbitmq-server')
  rabbit_ip_address = rabbit[0]['ipaddress']

  # Lookup keystone api ip address
  keystone = search(:node, 'role:keystone')
  keystone_api_ip = keystone[0]['api_ipaddress']
  keystone_service_port = keystone[0]['service_port']

  # Lookup glance api ip address
  glance = search(:node, 'role:glance-api')
  glance_api_ip = glance[0]['api_ipaddress']
  glance_api_port = glance[0]['api_port']
end

template "/etc/nova/nova.conf" do
  source "nova.conf.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(
    :user => node["nova"]["db_user"],
    :passwd => node["nova"]["db_passwd"],
    :ip_address => node["controller_ipaddress"],
    :db_name => node["nova"]["db"],
    :db_ipaddress => db_ip_address,
    :rabbit_ipaddress => rabbit_ip_address,
    :keystone_api_ipaddress => keystone_api_ip,
    :glance_api_ipaddress => glance_api_ip,
    :api_port => glance_api_port,
    :ipv4_cidr => node["public"]["ipv4_cidr"],
    :virt_type => node["virt_type"]
  )
end

template "/root/.novarc" do
  source "novarc.erb"
  owner "root"
  group "root"
  mode "0600"
  variables(
    :user => 'admin',
    :tenant => 'openstack',
    :password => 'secrete',
    :keystone_api_ipaddress => keystone_api_ip,
    :keystone_service_port => keystone_service_port,
    :nova_api_ipaddress => node["nova"]["api_ipaddress"],
    :nova_api_version => '1.1',
    :keystone_region => 'RegionOne',
    :auth_strategy => 'keystone',
    :ec2_url => "http://#{node['nova']['api_ipaddress']}:8773/services/Cloud",
    :ec2_access_key => node["credentials"]["EC2"]["admin"]["access"],
    :ec2_secret_key => node["credentials"]["EC2"]["admin"]["secret"]
  )
end
