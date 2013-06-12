#
# Cookbook Name:: openstack-compute
# Recipe:: ceilometer-collector
#
# Copyright 2012, AT&T
# Copyright 2013, Craig Tracey <craigtracey@gmail.com>
# Copyright 2013, SUSE Linux GmbH
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

include_recipe "openstack-compute::ceilometer-common"

ceilometer_conf = node["openstack"]["compute"]["ceilometer"]["conf"]
conf_switch = "--config-file #{ceilometer_conf}"
platform = node["openstack"]["compute"]["platform"]


execute "database migration" do
  command "ceilometer-dbsync #{conf_switch}"
end

if platform["ceilometer_packages"]
  platform["ceilometer_packages"]["collector"].each do |pkg|
    package pkg
  end

  service platform["ceilometer_services"]["collector"] do
    action :start
  end
else
  class ::Chef::Recipe
    include ::Openstack
  end

  bindir = "/usr/local/bin"

  service "ceilometer-collector" do
    action [:start]
    start_command "nohup #{bindir}/ceilometer-collector #{conf_switch} &"
    stop_command "pkill -f ceilometer-collector"
  end
end
