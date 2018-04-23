# libvirtd_opts used in template for /etc/default/libvirt-bin
default['openstack']['compute']['libvirt']['libvirtd_opts'] = '-l'

default['openstack']['compute']['libvirt']['auth_tcp'] = 'none'
# libvirt.max_clients (default: 20)
default['openstack']['compute']['libvirt']['max_clients'] = 20
# libvirt.max_workers (default: 20)
default['openstack']['compute']['libvirt']['max_workers'] = 20
# libvirt.max_requests (default: 20)
default['openstack']['compute']['libvirt']['max_requests'] = 20
# libvirt.max_client_requests (default: 5)
default['openstack']['compute']['libvirt']['max_client_requests'] = 5
default['openstack']['compute']['libvirt']['group'] = 'libvirt'
default['openstack']['compute']['libvirt']['unix_sock_rw_perms'] = '0770'
default['openstack']['compute']['libvirt']['libvirt_inject_key'] = true
default['openstack']['compute']['libvirt']['volume_backend'] = nil
