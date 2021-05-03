#
# Cookbook:: openstack-compute
# Recipe:: vncproxy
#
# Copyright:: 2012, Rackspace US, Inc.
# Copyright:: 2013, Craig Tracey <craigtracey@gmail.com>
# Copyright:: 2020, Oregon State University
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

include_recipe 'openstack-compute::nova-common'

platform_options = node['openstack']['compute']['platform']

package platform_options['compute_vncproxy_packages'] do
  options platform_options['package_overrides']
  action :upgrade
end

# required for vnc console authentication
package platform_options['compute_vncproxy_consoleauth_packages'] do
  action :upgrade
end

proxy_service = platform_options['compute_vncproxy_service']

service proxy_service do
  service_name proxy_service
  supports status: true, restart: true
  action [:enable, :start]
  subscribes :restart, 'template[/etc/nova/nova.conf]'
end

service 'nova-consoleauth' do
  service_name platform_options['compute_vncproxy_consoleauth_service']
  supports status: true, restart: true
  action [:enable, :start]
  subscribes :restart, 'template[/etc/nova/nova.conf]'
end
