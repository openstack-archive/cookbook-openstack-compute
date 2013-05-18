#
# Cookbook Name:: openstack-compute
# Recipe:: ceilometer-collector
#
# Copyright 2012, AT&T
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

class ::Chef::Recipe
  include ::Openstack
end

include_recipe "openstack-compute::ceilometer-common"

release = node["openstack"]["release"] || 'grizzly'

bindir = '/usr/local/bin'
install_dir = node["openstack"]["compute"]["ceilometer"]["install_dir"]
ceilometer_conf = node["openstack"]["compute"]["ceilometer"]["conf"]
conf_switch = "--config-file #{ceilometer_conf}"

# db migration
bash "migration" do
  code <<-EOF
    ceilometer-dbsync #{conf_switch}
  EOF
end

service "ceilometer-collector" do
  service_name "ceilometer-collector"
  action [:start]
  start_command "nohup #{bindir}/ceilometer-collector #{conf_switch} &"
  stop_command "pkill -f ceilometer-collector"
end
