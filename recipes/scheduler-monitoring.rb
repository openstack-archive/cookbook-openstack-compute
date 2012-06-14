#
# Cookbook Name:: nova
# Recipe:: scheduler-monitoring
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
# BEGIN MONIT SECTION
# Allow for enable/disable of monit
if node["enable_monit"]
  include_recipe "monit::server"
  platform_options = node["nova"]["platform"]

  monit_procmon "nova-scheduler" do
    process_name "nova-scheduler"
    start_cmd "/usr/sbin/service " + platform_options["nova_scheduler_service"] + " start"
    stop_cmd "/usr/sbin/service " + platform_options["nova_scheduler_service"] + " stop"
  end
end
########################################
