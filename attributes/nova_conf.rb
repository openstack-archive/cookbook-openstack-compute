
default['openstack']['compute']['conf_secrets'] = {}

default['openstack']['compute']['conf'].tap do |conf|
  # [DEFAULT] section
  conf['DEFAULT']['log_dir'] = '/var/log/nova'
  conf['DEFAULT']['state_path'] = '/var/lib/nova'
  conf['DEFAULT']['compute_driver'] = 'libvirt.LibvirtDriver'
  conf['DEFAULT']['auth_version'] = node['openstack']['api']['auth']['version']
  conf['DEFAULT']['instances_path'] = "#{node['openstack']['compute']['conf']['DEFAULT']['state_path']}/instances"
  conf['DEFAULT']['enabled_apis'] = 'osapi_compute'
  if node['openstack']['compute']['syslog']['use'] #= false
    conf['DEFAULT']['log_config'] = '/etc/openstack/logging.conf'
  end

  # [keystone_authtoken]
  conf['keystone_authtoken']['auth_type'] = 'v3password'
  conf['keystone_authtoken']['region_name'] = node['openstack']['region']
  conf['keystone_authtoken']['username'] = 'nova'
  conf['keystone_authtoken']['user_domain_name'] = 'Default'
  conf['keystone_authtoken']['project_domain_name'] = 'Default'
  conf['keystone_authtoken']['project_name'] = 'service'
  conf['keystone_authtoken']['auth_version'] = 'v3'

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
  conf['neutron']['auth_type'] = 'v3password'
  conf['neutron']['region_name'] = node['openstack']['region']
  conf['neutron']['username'] = 'neutron'
  conf['neutron']['user_domain_name'] = 'Default'
  conf['neutron']['service_metadata_proxy'] = true
  conf['neutron']['project_name'] = 'service'
  conf['neutron']['project_domain_name'] = 'Default'

  # [cinder] section
  conf['cinder']['os_region_name'] = node['openstack']['region']

  # [oslo_concurrency] section
  conf['oslo_concurrency']['lock_path'] = "#{node['openstack']['compute']['conf']['DEFAULT']['state_path']}/lock"

  # [placement] section
  conf['placement']['auth_type'] = 'password'
  conf['placement']['os_region_name'] = node['openstack']['region']
  conf['placement']['username'] = 'placement'
  conf['placement']['user_domain_name'] = 'Default'
  conf['placement']['project_domain_name'] = 'Default'
  conf['placement']['project_name'] = 'service'

  # [scheduler] section
  conf['scheduler']['discover_hosts_in_cells_interval'] = 300
end
