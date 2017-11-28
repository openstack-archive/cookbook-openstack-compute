# encoding: UTF-8
#
# Cookbook Name:: openstack-compute
# Recipe:: _nova_cell
#
# Copyright 2017, Workday, Inc.
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

# This recipe is automatically included in openstack-compute::api-os-compute
# and not called directly. It creates a basic cellv2 setup, which is required
# from Ocata forward.

class ::Chef::Recipe
  include ::Openstack
end

nova_user = node['openstack']['compute']['user']
nova_group = node['openstack']['compute']['group']
db_user = node['openstack']['db']['compute_cell0']['username']
db_password = get_password('db', 'nova_cell0')
uri = db_uri('compute_cell0', db_user, db_password)

execute 'map cell0' do
  user nova_user
  group nova_group
  command "nova-manage cell_v2 map_cell0 --database_connection #{uri}"
  not_if 'nova-manage cell_v2 list_cells | grep -q cell0'
  action :run
end

execute 'create cell1' do
  user nova_user
  group nova_group
  not_if 'nova-manage cell_v2 list_cells | grep -q cell1'
  command 'nova-manage cell_v2 create_cell --verbose --name cell1'
  action :run
end

execute 'api db sync' do
  timeout node['openstack']['compute']['dbsync_timeout']
  user nova_user
  group nova_group
  command 'nova-manage api_db sync'
  action :run
end

execute 'db sync' do
  timeout node['openstack']['compute']['dbsync_timeout']
  user nova_user
  group nova_group
  command 'nova-manage db sync'
  action :run
end

execute 'discover hosts' do
  user nova_user
  group nova_group
  command 'nova-manage cell_v2 discover_hosts'
  action :run
end
