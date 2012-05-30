#
# Cookbook Name:: nova
# Recipe:: vncproxy
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

platform_options = node["nova"]["platform"]

case node["platform"]
when "ubuntu","debian"
  platform_options["nova_vncproxy_packages"].each do |pkg|
    package pkg do
      action :upgrade
      options platform_options["package_overrides"]
    end
  end

  # required for vnc console authentication
  platform_options["nova_vncproxy_consoleauth_packages"].each do |pkg|
    package pkg do
      action :upgrade
    end
  end

  execute "Fix permission Bug" do
    command "sed -i 's/nova$/root/g' /etc/init/nova-vncproxy.conf"
    action :run
    only_if { File.readlines("/etc/init/nova-vncproxy.conf").grep(/exec.*nova$/).size > 0 }
  end

  service "nova-vncproxy" do
    # TODO(breu): remove the platform specifier when fedora fixes their vncproxy package
    service_name platform_options["nova_vncproxy_service"]
    supports :status => true, :restart => true
    action :enable
    subscribes :restart, resources(:template => "/etc/nova/nova.conf"), :delayed
  end

  service "nova-consoleauth" do
    # TODO(breu): remove the platform specifier when fedora fixes their vncproxy package
    service_name platform_options["nova_vncproxy_consoleauth_service"]
    supports :status => true, :restart => true
    action :enable
    subscribes :restart, resources(:template => "/etc/nova/nova.conf"), :delayed
  end
end
