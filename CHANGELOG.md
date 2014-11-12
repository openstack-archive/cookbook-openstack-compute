# CHANGELOG for cookbook-openstack-compute

This file is used to list changes made in each version of cookbook-openstack-compute.

## 10.0.0
* Upgrading to Juno
* Sync conf files with Juno
* Upgrading berkshelf from 2.0.18 to 3.1.5
* rng_dev_path in nova.conf configured from node attribute
* Add cafile, memcached_servers, memcache_security_strategy, memcache_secret_key, insecure and hash_algorithms so that they are configurable.
* Update nova.conf mode from 644 to 640
* Add support vnc_keymap from attribute ( default: en-us )
* Add vnc attributes for ssl_only, cert and key
* Bump Chef gem to 11.16
* Separate endpoints for vncserver_listen and vncserver_proxyclient_address
* Add more neutron section attributes
* Add glance_api_insecure and neutron_api_insecure; make glance_api_servers and neutron_url to be prefixed with scheme
* Add [ssl] section, needed to communicate with Glance when using https; add cinder_ca_certificates_file and cinder_api_insecure
* Add more attributes for nova.conf DEFAULT section
* Update and remove the outdated options
* Add cinder_catalog_info

## 9.3.1
* Move auth configuration from api-paste.ini to nova.conf
* fix fauxhai version for suse and redhat
* Allow scheduler_available_filters and compute_manager to have attribute overrides
* Allow rootwrap.conf attributes

## 9.3.0
* python_packages database client attributes have been migrated to the -common cookbook
* bump berkshelf to 2.0.18 to allow Supermarket support
* Allow metadata listen host and port to be configured

## 9.2.10
* Allow flat_injected and use_ipv6 to have attribute overrides

## 9.2.9
* Allow live migration to have attribute overrides

## 9.2.8
* Allow inject_partition to have attribute overrides

## 9.2.7
* Remove the storage_availability_zone settings

## 9.2.6
* Allow resize_confirm_window to have attribute overrides

## 9.2.5
* Create state and lock directories

## 9.2.4
* Allow dnsmasq_config_file to have attribute overrides

## 9.2.3
* Allow unix_sock_rw_perms to have attribute overrides

## 9.2.2
* Fix to allow workers to have attribute overrides

## 9.2.1
* Fix to allow compute driver attributes

## 9.2.0
* Get VMware vCenter password from databag

## 9.1.1
* Fix package action to allow updates

## 9.1.0
* Remove openrc, it's been moved to Common

## 9.0.1
### Bug
* Add network_allocate_retries option to nova.conf template

## 9.0.0
* Upgrade to Icehouse

## 8.4.2
* Fixing allow nova compute and ec2 ip and port to be configured

## 8.4.1
### Bug
* Fix the DB2 ODBC driver issue

## 8.4.0
### Blue print
* Use the library method auth_uri_transform

## 8.3.1
* Fixes including api-metadata recipe only when asked for (LP: 1286300)

## 8.3.0
* VMware compute driver support

## 8.2.1:
* Add the libvirt_inject_key attribute, defaults to true
* Add metering attributes

## 8.2.0
* Add client recipe

## 8.1.0
* Update to reflect changes in v3 of yum cookbook. Yum v3 now required.

## 8.0.0
* Branch for Havana. Add neutron support by search/replace quantum with neutron

## 7.3.0
* Add new attributes: auto_assign_floating_ip, disk_allocation_ratio, allow_resize_to_same_host
  and force_dhcp_release

## 7.2.4
### Bug
* Fixing console auth service and process names for RHEL (LP: 1256456)

## 7.2.3
* relax the dependencies to the 7.x series

## 7.2.2
### Bug
* Setting the libvirt_cpu_mode is none when libvirt_type is qemu (LP: 1255840)

## 7.2.1
* Add new attributes for common rpc configuration

## 7.2.0:
* adds qpid support. defaults to rabbit

## 7.1.0:
* adds the enabled_apis attribute, defaults to 'ec2,osapi_compute,metadata'

## 7.0.3:
* adds the libvirt_inject_password attribute, defaults to false

## 7.0.2:
* add the new attribute dbus_service settings for different OS platform.

## 7.0.2:
* Check the run_context.loaded_recipes rather than the run_list, since the
  'openstack-network::server' recipe is most likely contained in a role and
  not explicitly in the run_list.
* The sysctl cookbook is unused and was removed as a dependency.

## 7.0.1:
* Adding attributes for libvirtd.conf settings (max_clients, max_workers,
  max_requests, max_client_requests).

## 7.0.0:
* Initial release of cookbook-openstack-compute.

- - -
Check the [Markdown Syntax Guide](http://daringfireball.net/projects/markdown/syntax) for help with Markdown.

The [Github Flavored Markdown page](http://github.github.com/github-flavored-markdown/) describes the differences between markdown on github and standard markdown.

