#
# Cookbook Name:: nova
# Recipe:: compute
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
include_recipe "nova::api-metadata"
include_recipe "nova::network"

platform_options = node["nova"]["platform"]
nova_compute_packages = platform_options["nova_compute_packages"]

if platform?(%w(ubuntu))
  if node["nova"]["libvirt"]["virt_type"] == "kvm"
    nova_compute_packages << "nova-compute-kvm"
  elsif node["nova"]["libvirt"]["virt_type"] == "qemu"
    nova_compute_packages << "nova-compute-qemu"
  end
end

nova_compute_packages.each do |pkg|
  package pkg do
    action :upgrade
    options platform_options["package_overrides"]
  end
end

cookbook_file "/etc/nova/nova-compute.conf" do
  source "nova-compute.conf"
  mode "0600"
  action :create
end

service "nova-compute" do
  service_name platform_options["nova_compute_service"]
  supports :status => true, :restart => true
  action :enable
  subscribes :restart, resources(:template => "/etc/nova/nova.conf"), :delayed
end

include_recipe "nova::libvirt"

# Include recipe(nova::compute-monitoring)
include_recipe "nova::compute-monitoring"
