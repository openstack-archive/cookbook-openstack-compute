#
# Cookbook Name:: nova
# Recipe:: nova-scheduler-patch
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

include_recipe "osops-utils"

# lp:bug https://bugs.launchpad.net/nova/+bug/1007573
# affinity filters don't work if scheduler_hints is None
template "/usr/share/pyshared/nova/scheduler/filters/affinity_filter.py" do
  source "patches/affinity_filter.py.2012.1+stable~20120612-3ee026e-0ubuntu1.2"
  owner "root"
  group "root"
  mode "0644"
  notifies :restart, resources(:service => "nova-scheduler"), :immediately
  only_if { ::Chef::Recipe::Patch.check_package_version("nova-scheduler","2012.1+stable~20120612-3ee026e-0ubuntu1.2",node) ||
    ::Chef::Recipe::Patch.check_package_version("nova-scheduler","2012.1+stable~20120612-3ee026e-0ubuntu1.3",node) }
end
