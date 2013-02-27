#
# Cookbook Name:: nova
# Recipe:: libvirt
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

platform_options = node["openstack-compute"]["platform"]

platform_options["libvirt_packages"].each do |pkg|
  package pkg do
    action :install
  end
end

execute "create libvirtd group" do
  # Trim preceding whitespace from lines.
  command <<-EOH.gsub /^\s+/, ""
    groupadd -f libvirtd
    usermod -G libvirtd nova
  EOH

  only_if { platform? %w{fedora redhat centos} }
end

# http://fedoraproject.org/wiki/Getting_started_with_OpenStack_EPEL#Installing_within_a_VM
# ln -s /usr/libexec/qemu-kvm /usr/bin/qemu-system-x86_64
link "/usr/bin/qemu-system-x86_64" do
  to "/usr/libexec/qemu-kvm"

  only_if { platform? %w{fedora redhat centos} }
end

service "dbus" do
  action [:enable, :start]
end

service "libvirt-bin" do
  service_name platform_options["libvirt_service"]
  supports :status => true, :restart => true

  action [:enable, :start]
end

#remove default network if exists
execute "Disabling default libvirt network" do
  command "virsh net-autostart default --disable"
end

execute "Deleting default libvirt network" do
  command "virsh net-destroy default"

  only_if "virsh net-list | grep -q default"
end

# TODO(breu): this section needs to be rewritten to support key privisioning
template "/etc/libvirt/libvirtd.conf" do
  source "libvirtd.conf.erb"
  owner  "root"
  group  "root"
  mode   00644
  variables(
    :auth_tcp => node["openstack-compute"]["libvirt"]["auth_tcp"]
  )

  notifies :restart, "service[libvirt-bin]", :immediately
  not_if { platform? "suse" }
end

template "/etc/default/libvirt-bin" do
  source "libvirt-bin.erb"
  owner  "root"
  group  "root"
  mode   00644

  notifies :restart, "service[libvirt-bin]", :immediately

  only_if { platform? %w{ubuntu debian} }
end

template "/etc/sysconfig/libvirtd" do
  source "libvirtd.erb"
  owner  "root"
  group  "root"
  mode   00644

  notifies :restart, "service[libvirt-bin]", :immediately

  only_if { platform? %w{fedora redhat centos} }
end
