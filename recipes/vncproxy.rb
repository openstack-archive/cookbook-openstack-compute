#
# Cookbook Name:: nova
# Recipe:: vncproxy
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

include_recipe "nova::nova-common"

platform_options = node["nova"]["platform"]

platform_options["nova_vncproxy_packages"].each do |pkg|
  package pkg do
    options platform_options["package_overrides"]

    action :upgrade
  end
end

# required for vnc console authentication
platform_options["nova_vncproxy_consoleauth_packages"].each do |pkg|
  package pkg do
    action :upgrade
  end
end

if node["nova"]["apply_novnc_patch"]
  # Brought in these patches, until we get an updated novnc package.
  # This allows vncproxy to run on port 80 and 443 (useful when fronting
  # it with a load balancer.
  # https://github.com/kanaka/noVNC/pull/245
  cookbook_file "/usr/share/novnc/vnc_auto.html" do
    source "vnc_auto.html"
    owner "root"
    group "root"
    mode 00644
  end

  cookbook_file "/usr/share/novnc/include/ui.js" do
    source "ui.js"
    owner "root"
    group "root"
    mode 00644
  end
end

service "nova-vncproxy" do
  service_name platform_options["nova_vncproxy_service"]
  supports :status => true, :restart => true
  subscribes :restart, resources("template[/etc/nova/nova.conf]")

  action :enable
end

service "nova-consoleauth" do
  service_name platform_options["nova_vncproxy_consoleauth_service"]
  supports :status => true, :restart => true
  subscribes :restart, resources("template[/etc/nova/nova.conf]")

  action [ :enable, :start ]
end
