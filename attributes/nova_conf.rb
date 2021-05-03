
default['openstack']['compute']['conf_secrets'] = {}

default['openstack']['compute']['conf'].tap do |conf|
  # [DEFAULT] section
  conf['DEFAULT']['log_dir'] = '/var/log/nova'
  conf['DEFAULT']['state_path'] = '/var/lib/nova'
  conf['DEFAULT']['compute_driver'] = 'libvirt.LibvirtDriver'
  conf['DEFAULT']['instances_path'] = "#{node['openstack']['compute']['conf']['DEFAULT']['state_path']}/instances"
  conf['DEFAULT']['enabled_apis'] = 'osapi_compute,metadata'
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
  conf['keystone_authtoken']['service_token_roles_required'] = true

  # [service_user]
  conf['service_user']['auth_type'] = 'password'
  conf['service_user']['username'] = 'nova'
  conf['service_user']['user_domain_name'] = 'Default'
  conf['service_user']['project_name'] = 'service'
  conf['service_user']['project_domain_name'] = 'Default'
  conf['service_user']['send_service_user_token'] = true

  # [libvirt]
  conf['libvirt']['virt_type'] = 'kvm'
  conf['libvirt']['images_type'] = 'default'

  if node['openstack']['compute']['conf']['libvirt']['images_type'] == 'lvm'
    conf['libvirt']['images_volume_group'] = nil
    conf['libvirt']['sparse_logical_volumes'] = false
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
  conf['placement']['region_name'] = node['openstack']['region']
  conf['placement']['username'] = 'placement'
  conf['placement']['user_domain_name'] = 'Default'
  conf['placement']['project_domain_name'] = 'Default'
  conf['placement']['project_name'] = 'service'

  # [scheduler] section
  conf['scheduler']['discover_hosts_in_cells_interval'] = 300
end
