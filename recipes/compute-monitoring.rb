#
# Cookbook Name:: nova
# Recipe:: compute-monitoring
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

########################################
# BEGIN COLLECTD SECTION
# TODO(shep): This needs to be encased in an if block for the collectd_enabled environment toggle

include_recipe "collectd-graphite::collectd-client"

ks_service_endpoint = get_access_endpoint("keystone", "keystone","service-api")
nova = get_settings_by_role("single-compute", "nova")
if nova["libvirt"]["virt_type"] == "qemu"
  virt_conn = "qemu:///system"
else
  virt_conn = "kvm:///"
end

collectd_plugin "libvirt" do
  options(
    "Connection"=>virt_conn,
    "HostnameFormat"=>"name",
    "RefreshInterval"=>60
  )
end
########################################


########################################
# BEGIN MONIT SECTION
# TODO(shep): This needs to be encased in an if block for the monit_enabled environment toggle

include_recipe "monit::server"
platform_options = node["nova"]["platform"]

monit_procmon "nova-compute" do
  process_name "nova-compute"
  start_cmd platform_options["monit_commands"]["nova-compute"]["start"]
  stop_cmd platform_options["monit_commands"]["nova-compute"]["stop"]
end
########################################
