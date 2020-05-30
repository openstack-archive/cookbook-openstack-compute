default['openstack']['placement']['conf_secrets'] = {}

default['openstack']['placement']['conf'].tap do |conf|
  # [DEFAULT] section
  conf['DEFAULT']['log_dir'] = '/var/log/placement'
  conf['DEFAULT']['state_path'] = '/var/lib/placement'
  if node['openstack']['placement']['syslog']['use']
    conf['DEFAULT']['log_config'] = '/etc/openstack/logging.conf'
  end

  # [api]
  conf['api']['auth_strategy'] = 'keystone'

  # [keystone_authtoken]
  conf['keystone_authtoken']['auth_type'] = 'password'
  conf['keystone_authtoken']['username'] = 'placement'
  conf['keystone_authtoken']['user_domain_name'] = 'Default'
  conf['keystone_authtoken']['project_domain_name'] = 'Default'
  conf['keystone_authtoken']['project_name'] = 'service'
end
