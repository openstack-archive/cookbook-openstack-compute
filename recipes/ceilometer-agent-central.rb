#
# Cookbook Name:: openstack-compute
# Recipe:: ceilometer-agent-central
#
# Copyright 2012, AT&T
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

class ::Chef::Recipe
  include ::Openstack
end

include_recipe "openstack-compute::ceilometer-common"

bindir = '/usr/local/bin'
ceilometer_conf = node["openstack"]["compute"]["ceilometer"]["conf"]
conf_switch = "--config-file #{ceilometer_conf}"

service "ceilometer-agent-central" do
  service_name "ceilometer-agent-central"
  action [:start]
  start_command "nohup #{bindir}/ceilometer-agent-central #{conf_switch} &"
  stop_command "pkill -f ceilometer-agent-central"
end
