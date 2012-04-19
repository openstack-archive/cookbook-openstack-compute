#
# Cookbook nova:volume
# Recipe:: default
#

include_recipe "nova::nova-common"
include_recipe "nova::api-os-volume"

# Distribution specific settings go here
if platform?(%w{fedora})
  # Fedora
  nova_volume_package = "openstack-nova"
  nova_volume_service = "openstack-nova-volume"
  nova_volume_package_options = ""
else
  # All Others (right now Debian and Ubuntu)
  nova_volume_package = "nova-volume"
  nova_volume_service = nova_volume_package
  nova_volume_package_options = "-o Dpkg::Options::='--force-confold' --force-yes"
end

package "python-keystone" do
  action :upgrade
end

package nova_volume_package do
  action :upgrade
  options nova_volume_package_options
end

service nova_volume_service do
  supports :status => true, :restart => true
  action :disable
  subscribes :restart, resources(:template => "/etc/nova/nova.conf"), :delayed
end

if Chef::Config[:solo]
  Chef::Log.warn("This recipe uses search. Chef Solo does not support search.")
else
  # Lookup keystone api ip address
  keystone = search(:node, "roles:keystone and chef_environment:#{node.chef_environment}") || []
  if keystone.length > 0
    Chef::Log.info("Using Keystone attributes from SEARCH")
    keystone_api_ip = keystone[0]['keystone']['api_ipaddress']
    keystone_admin_port = keystone[0]['keystone']['admin_port']
    keystone_admin_token = keystone[0]['keystone']['admin_token']
  else
    Chef::Log.info("Using Keystone attributes from NODE")
    keystone_api_ip = node['keystone']['api_ipaddress']
    keystone_admin_port = node['keystone']['admin_port']
    keystone_admin_token = node['keystone']['admin_token']
  end
end

# Register Volume Service
keystone_register "Register Volume Service" do
  auth_host keystone_api_ip
  auth_port keystone_admin_port
  auth_protocol "http"
  api_ver "/v2.0"
  auth_token keystone_admin_token
  service_name "Volume Service"
  service_type "volume"
  service_description "Nova Volume Service"
  action :create_service
end

node["volume"]["adminURL"] = "http://#{node["volume"]["ipaddress"]}:#{node["volume"]["api_port"]}/v1/%(tenant_id)s"
node["volume"]["internalURL"] = node["volume"]["adminURL"]
node["volume"]["publicURL"] = node["volume"]["adminURL"]

# Register Image Endpoint
keystone_register "Register Volume Endpoint" do
  auth_host keystone_api_ip
  auth_port keystone_admin_port
  auth_protocol "http"
  api_ver "/v2.0"
  auth_token keystone_admin_token
  service_type "volume"
  endpoint_region "RegionOne"
  endpoint_adminurl node["volume"]["adminURL"]
  endpoint_internalurl node["volume"]["internalURL"]
  endpoint_publicurl node["volume"]["publicURL"]
  action :create_endpoint
end
