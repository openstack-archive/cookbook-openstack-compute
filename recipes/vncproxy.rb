#
# Cookbook Name:: nova
# Recipe:: vncproxy
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

include_recipe "nova::nova-common"

# Distribution specific settings go here
if platform?(%w{fedora})
  # Fedora
  # TODO(breu): fedora doesn't have a working vncproxy yet.  Once they fix it include it here
  # TODO(breu): fedora packages consoleauth but they don't include systemd startup scripts
  nova_vncproxy_package = "openstack-nova"
  nova_vncproxy_service = "openstack-nova-vncproxy"
  nova_vncproxy_consoleauth_package = "openstack-nova"
  #nova_vncproxy_consoleauth_service = ""
  #nova_vncproxy_package_options = ""
else
  # All Others (right now Debian and Ubuntu)
  nova_vncproxy_package = "nova-vncproxy"
  nova_vncproxy_service = nova_vncproxy_package
  nova_vncproxy_consoleauth_package = "nova-consoleauth"
  nova_vncproxy_consoleauth_service = nova_vncproxy_consoleauth_package
  nova_vncproxy_package_options = "-o Dpkg::Options::='--force-confold' --force-yes"
end

package nova_vncproxy_package do
  action :upgrade
  only_if do platform?("ubuntu","debian") end
end

# required for vnc console authentication
package nova_vncproxy_consoleauth_package do
  action :upgrade
  only_if do platform?("ubuntu","debian") end
end

execute "Fix permission Bug" do
  command "sed -i 's/nova$/root/g' /etc/init/nova-vncproxy.conf"
  action :run
  only_if { File.readlines("/etc/init/nova-vncproxy.conf").grep(/exec.*nova$/).size > 0 and platform?("ubuntu","debian")}
end

service nova_vncproxy_service do
  # TODO(breu): remove the platform specifier when fedora fixes their vncproxy package
  supports :status => true, :restart => true
  action :enable
  subscribes :restart, resources(:template => "/etc/nova/nova.conf"), :delayed
  only_if do platform?("ubuntu","debian") end
end

service nova_vncproxy_consoleauth_service do
  # TODO(breu): remove the platform specifier when fedora fixes their vncproxy package
  supports :status => true, :restart => true
  action :enable
  subscribes :restart, resources(:template => "/etc/nova/nova.conf"), :delayed
  only_if do platform?("ubuntu","debian") end
end
