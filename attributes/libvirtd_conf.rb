# libvirtd_opts used in template for /etc/default/libvirt-bin
default['openstack']['compute']['libvirt']['libvirtd_opts'] = '-l'

default['openstack']['compute']['libvirt']['group'] = 'libvirt'
default['openstack']['compute']['libvirt']['volume_backend'] = nil

default['openstack']['compute']['libvirt']['conf'].tap do |conf|
  conf['listen_tls'] = '0'
  conf['listen_tcp'] = '1'
  conf['unix_sock_rw_perms'] = '"0770"'
  conf['auth_unix_ro'] = '"none"'
  conf['auth_unix_rw'] = '"none"'
  conf['auth_tcp'] = '"none"'
  conf['max_clients'] = '20'
  conf['max_workers'] = '20'
  conf['max_requests'] = '20'
  conf['max_client_requests'] = '5'
end
