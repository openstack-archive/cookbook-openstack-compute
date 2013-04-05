#
# Cookbook Name:: nova
# Recipe:: ceilometer-api
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

include_recipe "nova::ceilometer-common"

nova_owner = node["nova"]["user"]
nova_group = node["nova"]["group"]

directory ::File.dirname(node["nova"]["api"]["auth"]["cache_dir"]) do
  owner node["nova"]["user"]
  group node["nova"]["group"]
  mode 00700

  only_if { node["openstack"]["auth"]["strategy"] == "pki" }
end

bindir = '/usr/local/bin'
ceilometer_conf = node["nova"]["ceilometer"]["conf"]
conf_switch = "--config-file #{ceilometer_conf}"

service "ceilometer-api" do
  service_name "ceilometer-api"
  action [:start]
  start_command "nohup #{bindir}/ceilometer-api #{conf_switch} &"
  stop_command "pkill -f ceilometer-api"
end
