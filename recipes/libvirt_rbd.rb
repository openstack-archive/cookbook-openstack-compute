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

include_recipe 'ceph'

ceph_user = node['openstack']['compute']['libvirt']['rbd']['cinder']['user']
cinder_pool = node['openstack']['compute']['libvirt']['rbd']['cinder']['pool']
nova_pool = node['openstack']['compute']['libvirt']['rbd']['nova']['pool']
glance_pool =  node['openstack']['compute']['libvirt']['rbd']['glance']['pool']

secret_uuid = node['openstack']['compute']['libvirt']['rbd']['cinder']['secret_uuid']
ceph_keyname = "client.#{ceph_user}"
ceph_keyring = "/etc/ceph/ceph.#{ceph_keyname}.keyring"

caps = { 'mon' => 'allow r',
         'osd' => "allow class-read object_prefix rbd_children, allow rwx pool=#{cinder_pool}, allow rwx pool=#{nova_pool}, allow rx pool=#{glance_pool}" }

ceph_client ceph_user do
  name ceph_user
  caps caps
  keyname ceph_keyname
  filename ceph_keyring
  owner node['openstack']['compute']['user']
  group node['openstack']['compute']['group']

  action :add
end

Chef::Log.info("rbd_secret_name: #{secret_uuid}")

template '/tmp/secret.xml' do
  source 'secret.xml.erb'
  user 'root'
  group 'root'
  mode '00600'
  variables(
    uuid: secret_uuid,
    client_name: node['openstack']['compute']['libvirt']['rbd']['cinder']['user']
  )
  not_if "virsh secret-list | grep #{secret_uuid}"
end

execute 'virsh secret-define --file /tmp/secret.xml' do
  not_if "virsh secret-list | grep #{secret_uuid}"
end

# this will update the key if necessary
execute "virsh secret-set-value --secret #{secret_uuid} --base64 $(ceph-authtool -p -n client.#{ceph_user} #{ceph_keyring})" do
  not_if "virsh secret-get-value #{secret_uuid} | grep $(ceph-authtool -p -n #{ceph_keyname} #{ceph_keyring})"
end

file '/tmp/secret.xml' do
  action :delete
end
