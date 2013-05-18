#
# Cookbook Name:: openstack-compute
# Recipe:: api-metadata
#
# Copyright 2012, Rackspace US, Inc.
# Copyright 2013, Craig Tracey <craigtracey@gmail.com>
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

include_recipe "openstack-compute::nova-common"

platform_options = node["openstack"]["compute"]["platform"]

directory "/var/lock/nova" do
  owner node["openstack"]["compute"]["user"]
  group node["openstack"]["compute"]["group"]
  mode  00700

  action :create
end

package "python-keystone" do
  action :upgrade
end

platform_options["compute_api_metadata_packages"].each do |pkg|
  package pkg do
    options platform_options["package_overrides"]

    action :upgrade
  end
end

service "nova-api-metadata" do
  service_name platform_options["compute_api_metadata_service"]
  supports :status => true, :restart => true
  subscribes :restart, resources("template[/etc/nova/nova.conf]")

  action :enable
end

identity_admin_endpoint = endpoint "identity-admin"
identity_service_role = node["openstack"]["compute"]["identity_service_chef_role"]

auth_uri = ::URI.decode identity_admin_endpoint.to_s
service_pass = service_password "nova"

template "/etc/nova/api-paste.ini" do
  source "api-paste.ini.erb"
  owner  node["openstack"]["compute"]["user"]
  group  node["openstack"]["compute"]["group"]
  mode   00644
  variables(
    :identity_admin_endpoint => identity_admin_endpoint,
    :service_pass => service_pass
  )

  notifies :restart, "service[nova-api-metadata]"
end
