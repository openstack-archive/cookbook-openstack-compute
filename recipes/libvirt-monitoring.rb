#
# Cookbook Name:: nova
# Recipe:: libvirt-monitoring
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
# Allow for enable/disable of collectd
if node["enable_collectd"]
  include_recipe "collectd-graphite::collectd-client"
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
end
########################################

########################################
# BEGIN MONIT SECTION
# Allow for enable/disable of monit
if node["enable_monit"]
  include_recipe "monit::server"
  platform_options = node["nova"]["platform"]

  monit_procmon "libvirt-bin" do
    process_name "libvirtd"
    start_cmd platform_options["monit_commands"]["libvirt-bin"]["start"]
    stop_cmd platform_options["monit_commands"]["libvirt-bin"]["stop"]
  end
end
########################################
