# CHANGELOG for cookbook-openstack-compute

This file is used to list changes made in each version of cookbook-openstack-compute.

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

