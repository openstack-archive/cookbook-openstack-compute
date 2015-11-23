
default['openstack']['compute']['conf_secrets'] = {}

default['openstack']['compute']['conf'].tap do |conf|
  # [DEFAULT] section
  conf['DEFAULT']['log_dir'] = '/var/log/nova'
  conf['DEFAULT']['state_path'] = '/var/lib/nova'
  conf['DEFAULT']['compute_driver'] = 'libvirt.LibvirtDriver'
  conf['DEFAULT']['auth_version'] = node['openstack']['api']['auth']['version']
  conf['DEFAULT']['rpc_backend'] = node['openstack']['mq']['service_type']
  conf['DEFAULT']['instances_path'] = "#{node['openstack']['compute']['conf']['DEFAULT']['state_path']}/instances"
  conf['DEFAULT']['enabled_apis'] = 'ec2,osapi_compute'
  if node['openstack']['compute']['syslog']['use'] #= false
    conf['DEFAULT']['log_config'] = '/etc/openstack/logging.conf'
  end

  conf['DEFAULT']['network_api_class'] = 'nova.network.neutronv2.api.API' # nova.network.api.API
  conf['DEFAULT']['linuxnet_interface_driver'] = 'nova.network.linux_net.LinuxOVSInterfaceDriver'
  conf['DEFAULT']['firewall_driver'] = 'nova.virt.firewall.NoopFirewallDriver'
  conf['DEFAULT']['security_group_api'] = 'neutron'
  conf['DEFAULT']['default_floating_pool'] = 'public' # not listed
  conf['DEFAULT']['dns_server'] = '8.8.8.8' # [] in docs

  # [keystone_authtoken]
  conf['keystone_authtoken']['signing_dir'] = '/var/cache/nova/api'
  conf['keystone_authtoken']['auth_plugin'] = 'v2password'
  conf['keystone_authtoken']['region_name'] = node['openstack']['region']
  conf['keystone_authtoken']['username'] = 'nova'
  conf['keystone_authtoken']['tenant_name'] = 'service'

  # [libvirt]
  conf['libvirt']['virt_type'] = 'kvm'
  conf['libvirt']['images_type'] = 'default'

  if node['openstack']['compute']['conf']['libvirt']['images_type'] == 'lvm'
    conf['libvirt']['images_volume_group'] = nil
    conf['libvirt']['sparse_logical_volumes'] = false

  elsif node['openstack']['compute']['conf']['libvirt']['images_type'] == 'rbd'
    conf['libvirt']['images_rbd_pool'] = 'instances'
    conf['libvirt']['images_rbd_ceph_conf'] = '/etc/ceph/ceph.conf' # nil
    conf['libvirt']['rbd_user'] = 'cinder' # none
    conf['libvirt']['rbd_secret_uuid'] = node['openstack']['compute']['libvirt']['rbd']['cinder']['secret_uuid']

  end

  # [neutron]
  conf['neutron']['auth_plugin'] = 'v2password'
  conf['neutron']['region_name'] = node['openstack']['region']
  conf['neutron']['username'] = 'neutron'
  conf['neutron']['tenant_name'] = 'service'
  conf['neutron']['service_metadata_proxy'] = true

  # [cinder] section
  conf['cinder']['os_region_name'] = node['openstack']['region']

  # [oslo_concurrency] section
  conf['oslo_concurrency']['lock_path'] = "#{node['openstack']['compute']['conf']['DEFAULT']['state_path']}/lock"
end
