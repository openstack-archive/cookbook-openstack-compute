# encoding: UTF-8
#
# Cookbook Name:: openstack-compute
# Recipe:: libvirt_rbd
#
# Copyright 2014, x-ion GmbH
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

class ::Chef::Recipe # rubocop:disable Documentation
  include ::Openstack
end

# include_recipe 'openstack-common::ceph_client'

platform_options = node['openstack']['compute']['platform']

platform_options['libvirt_ceph_packages'].each do |pkg|
  package pkg do
    action :install
  end
end

# TODO(srenatus) there might be multiple secrets, cinder will tell nova-compute
# which one should be used for each single volume mount request
Chef::Log.info("rbd_secret_name: #{node['openstack']['compute']['libvirt']['rbd']['rbd_secret_name']}")
secret_uuid = secret 'secrets', node['openstack']['compute']['libvirt']['rbd']['rbd_secret_name']
ceph_key = get_password 'service', 'rbd_block_storage'

require 'securerandom'
filename = SecureRandom.hex

template "/tmp/#{filename}.xml" do
  source 'secret.xml.erb'
  user 'root'
  group 'root'
  mode '700'
  variables(
    uuid: secret_uuid,
    client_name: node['openstack']['compute']['libvirt']['rbd']['rbd_user']
  )
  not_if "virsh secret-list | grep #{secret_uuid}"
end

execute "virsh secret-define --file /tmp/#{filename}.xml" do
  not_if "virsh secret-list | grep #{secret_uuid}"
end

# this will update the key if necessary
execute "virsh secret-set-value --secret #{secret_uuid} '#{ceph_key}'" do
  not_if "virsh secret-get-value #{secret_uuid} | grep '#{ceph_key}'"
end

file "/tmp/#{filename}.xml" do
  action :delete
end
