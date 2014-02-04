# encoding: UTF-8
#
# Cookbook Name:: openstack-compute
# Recipe:: nova-setup
#
# Copyright 2012, Rackspace US, Inc.
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

include_recipe 'openstack-compute::nova-common'

execute 'nova-manage db sync' do
  user node['openstack']['compute']['user']
  group node['openstack']['compute']['group']
  command 'nova-manage db sync'
  action :run
end

case node['openstack']['compute']['network']['service_type']
when 'nova'

  next_vlan = 100
  node['openstack']['compute']['networks'].each do |net|
    execute "nova-manage network create --label=#{net['label']}" do
      user node['openstack']['compute']['user']
      group node['openstack']['compute']['group']

      # The only two required keys in each network Hash
      # are 'label' and 'ipv4_cidr'.
      cmd = "nova-manage network create --label=#{net['label']} --fixed_range_v4=#{net['ipv4_cidr']}"
      cmd += " --multi_host='#{net['multi_host']}'" if net.key?('multi_host')
      %w{num_networks network_size bridge dns1 dns2}.each do |v|
        cmd += " --#{v}=#{net[v]}" if net.key?(v)
      end
      # Older attributes have the key as 'bridge_dev' instead
      # of 'bridge_interface'...
      if net.key?('bridge_interface') || net.key?('bridge_dev')
        val = net.key?('bridge_interface') ? net['bridge_interface'] : net['bridge_dev']
        cmd += " --bridge_interface=#{val}"
      end
      if net.key?('vlan')
        cmd += " --vlan=#{net['vlan']}"
      elsif node['openstack']['compute']['network']['network_manager'] == 'nova.network.manager.VlanManager'
        cmd += " --vlan=#{next_vlan}"
        next_vlan = next_vlan + 1
      end
      command cmd
      not_if "nova-manage network list | grep #{net['ipv4_cidr']}"

      action :run
    end
  end

  cookbook_file node['openstack']['compute']['floating_cmd'] do
    source 'add_floaters.py'
    mode   00755

    action :create
  end

  floating = node['openstack']['compute']['network']['floating']
  if floating && (floating['ipv4_cidr'] || floating['ipv4_range'])
    cmd = ''
    if floating['ipv4_cidr']
      cmd = "#{node['openstack']['compute']['floating_cmd']} nova --cidr=#{floating['ipv4_cidr']}"
    elsif floating['ipv4_range']
      cmd = "#{node['openstack']['compute']['floating_cmd']} nova --ip-range=#{floating['ipv4_range']}"
    end

    execute 'nova-manage floating create' do
      user node['openstack']['compute']['user']
      group node['openstack']['compute']['group']
      command cmd

      not_if "nova-manage floating list |grep -E '.*([0-9]{1,3}[\.]){3}[0-9]{1,3}*'"

      action :run
    end
  end

when 'neutron'

  platform_options = node['openstack']['compute']['platform']

  platform_options['neutron_python_packages'].each do |pkg|
    package pkg do
      options platform_options['package_overrides']
      action :upgrade
    end
  end

  cookbook_file node['openstack']['compute']['floating_cmd'] do
    source 'add_floaters.py'
    mode   00755

    action :create
  end

  floating = node['openstack']['compute']['network']['floating']
  if floating && floating['ipv4_cidr']
    cmd = ". /root/openrc && #{node['openstack']['compute']['floating_cmd']} neutron --cidr=#{floating['ipv4_cidr']} --pool=#{floating['public_network_name']}"

    execute 'neutron floating create' do
      command cmd
      not_if ". /root/openrc && neutron floatingip-list |grep -E '.*([0-9]{1,3}[\.]){3}[0-9]{1,3}*'"
      only_if { File.exists?('/root/openrc') }

      action :run
    end
  end
end
