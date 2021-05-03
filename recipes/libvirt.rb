#
# Cookbook:: openstack-compute
# Recipe:: libvirt
#
# Copyright:: 2012, Rackspace US, Inc.
# Copyright:: 2013, Craig Tracey <craigtracey@gmail.com>
# Copyright:: 2020, Oregon State University
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

require 'mixlib/shellout'

platform_options = node['openstack']['compute']['platform']

package platform_options['libvirt_packages'] do
  options platform_options['package_overrides']
  action :upgrade
end

# TODO: (jklare) methods do not belong in recipes, this has to be moved!
def update_grub_default_kernel(flavor = 'default')
  default_boot = 0
  current_default = nil

  # parse menu.lst, to find boot index for selected flavor
  File.open('/boot/grub/menu.lst') do |f|
    f.lines.each do |line|
      current_default = line.scan(/\d/).first.to_i if line.start_with?('default')

      next unless line.start_with?('title')
      if flavor.eql?('xen')
        # found boot index
        break if line.include?('Xen')
      else
        # take first kernel as default, unless we are searching for xen
        # kernel
        break
      end
      default_boot += 1
    end
  end

  # change default option for /boot/grub/menu.lst
  unless current_default.eql?(default_boot)
    ::Chef::Log.info("Changed grub default to #{default_boot}")
    shell_out("sed -i -e 's;^default.*;default #{default_boot};' /boot/grub/menu.lst")
  end
end

def update_boot_kernel_and_trigger_reboot(flavor = 'default')
  # only default and xen flavor is supported by this helper right now
  if File.exist?('/boot/grub/menu.lst')
    update_grub_default_kernel(flavor)
  elsif File.exist?('/etc/default/grub')
    update_grub2_default_kernel(flavor)
  else
    ::Chef::Application.fatal!(
      'Unknown bootloader. Could not change boot kernel.'
    )
  end

  # trigger reboot through reboot_handler, if kernel-$flavor is not yet
  # running
  unless shell_out('uname -r').stdout.include?(flavor)
    node.run_state['reboot'] = true
  end
end

libvirt_group = node['openstack']['compute']['libvirt']['group']
group libvirt_group do
  append true
  members [node['openstack']['compute']['group']]
  action :create
  only_if { platform_family? %w(rhel) }
end

# http://fedoraproject.org/wiki/Getting_started_with_OpenStack_EPEL#Installing_within_a_VM
# ln -s /usr/libexec/qemu-kvm /usr/bin/qemu-system-x86_64
link '/usr/bin/qemu-system-x86_64' do
  to '/usr/libexec/qemu-kvm'
  only_if { platform_family? %w(rhel) }
end

service 'dbus' do
  service_name platform_options['dbus_service']
  supports status: true, restart: true
  action [:enable, :start]
end

service 'libvirt-bin' do
  service_name platform_options['libvirt_service']
  supports status: true, restart: true
  action [:enable, :start]
end

execute 'Deleting default libvirt network' do
  command 'virsh net-destroy default'
  only_if 'virsh net-list | grep -q default'
end

node.default['openstack']['compute']['libvirt']['conf']['unix_sock_group'] = "'#{libvirt_group}'"

template '/etc/libvirt/libvirtd.conf' do
  source 'libvirtd.conf.erb'
  owner 'root'
  group 'root'
  mode '644'
  variables(
    service_config: node['openstack']['compute']['libvirt']['conf']
  )
  notifies :restart, 'service[libvirt-bin]', :immediately
end

# The package libvirt-bin on debian now provides the service libvirtd
# (libvirt-bin is still defined as an alias) and reads its environment from
# /etc/libvirt/libvirtd instead of the previously used
# /etc/default/libvirt-bin.
template '/etc/default/libvirtd' do
  source 'libvirt-bin.erb'
  owner 'root'
  group 'root'
  mode '644'
  notifies :restart, 'service[libvirt-bin]', :immediately
  only_if { platform_family? 'debian' }
end

template '/etc/sysconfig/libvirtd' do
  source 'libvirtd.erb'
  owner 'root'
  group 'root'
  mode '644'
  notifies :restart, 'service[libvirt-bin]', :immediately
  only_if { platform_family? %w(rhel) }
end

volume_backend = node['openstack']['compute']['libvirt']['volume_backend']
include_recipe "openstack-compute::libvirt_#{volume_backend}" unless volume_backend.nil?
