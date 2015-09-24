# encoding: UTF-8
#
# Cookbook Name:: openstack-compute
# Recipe:: libvirt
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

require 'mixlib/shellout'

platform_options = node['openstack']['compute']['platform']

platform_options['libvirt_packages'].each do |pkg|
  package pkg do
    options platform_options['package_overrides']
    action :upgrade
  end
end

def update_grub_default_kernel(flavor = 'default') # rubocop:disable MethodLength
  default_boot = 0
  current_default =		 nil

  # parse menu.lst, to find boot index for selected flavor
  File.open('/boot/grub/menu.lst') do |f|
    f.lines.each do |line|
      current_default = line.scan(/\d/).first.to_i if line.start_with?('default')

      if line.start_with?('title')
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
  end

  # change default option for /boot/grub/menu.lst
  unless current_default.eql?(default_boot)
    ::Chef::Log.info('Changed grub default to #{default_boot}')
    Mixlib::ShellOut.new('sed -i -e \'s;^default.*;default #{default_boot};\' /boot/grub/menu.lst').run_command
  end
end

def update_grub2_default_kernel(flavor = 'default')
  boot_entry = "'openSUSE GNU/Linux, with Xen hypervisor'"
  begin
    Mixlib::ShellOut.new("grub2-set-default #{boot_entry}").run_command.error!
    ::Chef::Log.info("Changed grub2 default to #{boot_entry}")
  rescue Mixlib::ShellOut::ShellCommandFailed => e
    ::Chef::Application.fatal!(
      "Unable to change grub2 default to #{boot_entry}
#{e.message}")
  end
end

def update_boot_kernel_and_trigger_reboot(flavor = 'default') # rubocop:disable MethodLength
  # only default and xen flavor is supported by this helper right now
  if File.exist?('/boot/grub/menu.lst')
    update_grub_default_kernel(flavor)
  elsif File.exist?('/etc/default/grub')
    update_grub2_default_kernel(flavor)
  else
    ::Chef::Application.fatal!(
      'Unknown bootloader. Could not change boot kernel.')
  end

  # trigger reboot through reboot_handler, if kernel-$flavor is not yet
  # running
  unless Mixlib::ShellOut.new('uname -r').run_command.stdout.include?(flavor)
    node.run_state['reboot'] = true
  end
end

# on suse nova-compute don't depends on any virtualization mechanism
case node['platform_family']
when 'suse'
  case node['openstack']['compute']['libvirt']['virt_type']
  when 'kvm'
    node['openstack']['compute']['platform']['kvm_packages'].each do |pkg|
      package pkg do
        options platform_options['package_overrides']
        action :upgrade
      end
    end
    execute 'loading kvm modules' do
      command 'grep -q vmx /proc/cpuinfo && /sbin/modprobe kvm-intel; grep -q svm /proc/cpuinfo && /sbin/modprobe kvm-amd; /sbin/modprobe vhost-net'
    end
    # NOTE(saschpe): Allow switching from XEN to KVM:
    update_boot_kernel_and_trigger_reboot

  when 'xen'
    node['openstack']['compute']['platform']['xen_packages'].each do |pkg|
      package pkg do
        options platform_options['package_overrides']
        action :upgrade
      end
    end
    update_boot_kernel_and_trigger_reboot('xen')

  when 'qemu'
    node['openstack']['compute']['platform']['kvm_packages'].each do |pkg|
      package pkg do
        options platform_options['package_overrides']
        action :upgrade
      end
    end

  when 'lxc'
    node['openstack']['compute']['platform']['lxc_packages'].each do |pkg|
      package pkg do
        options platform_options['package_overrides']
        action :upgrade
      end
    end
    service 'boot.cgroup' do
      action [:enable, :start]
    end
  end
end

group node['openstack']['compute']['libvirt']['group'] do
  append true
  members [node['openstack']['compute']['group']]

  action :create
  only_if { platform_family? %w(suse fedora rhel) }
end

# http://fedoraproject.org/wiki/Getting_started_with_OpenStack_EPEL#Installing_within_a_VM
# ln -s /usr/libexec/qemu-kvm /usr/bin/qemu-system-x86_64
link '/usr/bin/qemu-system-x86_64' do
  to '/usr/libexec/qemu-kvm'

  only_if { platform_family? %w(fedora rhel) }
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

# TODO(breu): this section needs to be rewritten to support key privisioning
template '/etc/libvirt/libvirtd.conf' do
  source 'libvirtd.conf.erb'
  owner 'root'
  group 'root'
  mode 00644
  variables(
    auth_tcp: node['openstack']['compute']['libvirt']['auth_tcp'],
    libvirt_group: node['openstack']['compute']['libvirt']['group']
  )

  notifies :restart, 'service[libvirt-bin]', :immediately
  not_if { platform_family? 'suse' }
end

template '/etc/default/libvirt-bin' do
  source 'libvirt-bin.erb'
  owner 'root'
  group 'root'
  mode 00644

  notifies :restart, 'service[libvirt-bin]', :immediately

  only_if { platform_family? 'debian' }
end

template '/etc/sysconfig/libvirtd' do
  source 'libvirtd.erb'
  owner 'root'
  group 'root'
  mode 00644

  notifies :restart, 'service[libvirt-bin]', :immediately

  only_if { platform_family? %w(fedora rhel) }
end

volume_backend = node['openstack']['compute']['libvirt']['volume_backend']
include_recipe "openstack-compute::libvirt_#{volume_backend}" unless volume_backend.nil?
