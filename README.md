Description
===========

This cookbook installs the OpenStack Compute service **Nova** as part
of a reference deployment Chef for OpenStack. The
http://github.com/opscode/openstack-chef-repo contains documentation
for using this cookbook in the context of a full OpenStack deployment.
Nova is installed from packages.

http://nova.openstack.org

Requirements
============

* Chef 0.10.0 or higher required (for Chef environment use).
* [Network Addr](https://gist.github.com/jtimberman/1040543) Ohai plugin.

Cookbooks
---------

The following cookbooks are dependencies:

* apache2
* database
* glance
* keystone
* mysql
* openstack-common
* rabbitmq
* selinux (Fedora)
* sysctl
* yum

Usage
=====

api-ec2
----
-Includes recipe `nova-common`
-Installs AWS EC2 compatible API and configures the service and endpoints in keystone

api-metadata
----
-Includes recipe `nova-common`
-Installs the nova metadata package

api-os-compute
----
-Includes recipe `nova-common`
-Installs OS API and configures the service and endpoints in keystone

api-os-volume
----
-Includes recipe `nova-common`
-Installs the OpenStack volume service API

compute
----
-Includes recipes `nova-common`, `api-metadata`, `network`
-Installs nova-compute service

db
--
-Configures database for use with nova

libvirt
----
-Installs libvirt, used by nova compute for management of the virtual machine environment

network
----
-Includes recipe `nova-common`
-Installs nova network service

nova-cert
----
- Installs nova-cert service

nova-common
----
-May include recipe `selinux` (Fedora)
-Builds the basic nova.conf config file with details of the rabbitmq, mysql, glance and keystone servers
-Builds a openrc file for root with appropriate environment variables to interact with the nova client CLI

nova-setup
----
-Includes recipes `nova-common`
-Sets up the nova networks with `nova-manage`

scheduler
----
-Includes recipe `nova-common`
-Installs nova scheduler service

vncproxy
----
-Includes recipe `nova-common`
-Installs and configures the vncproxy service for console access to VMs

volume
----
-Includes recipes `nova-common`, `api-os-volume`
-Installs nova volume service and configures the service and endpoints in keystone


Attributes
==========

* `default["openstack-compute"]["keystone_service_chef_role"]` - The name of the Chef role that sets up the Keystone Service API
* `default["openstack-compute"]["user"]` - User nova services run as
* `default["openstack-compute"]["group"]` - Group nova services run as
* `default["openstack-compute"]["db"]["username"]` - Username for nova database access
* `default["openstack-compute"]["rabbit"]["username"]` - Username for nova rabbit access
* `default["openstack-compute"]["rabbit"]["vhost"]` - The rabbit vhost to use
* `default["openstack-compute"]["service_tenant_name"]` - Tenant name used by nova when interacting with keystone
* `default["openstack-compute"]["service_user"]` - User name used by nova when interacting with keystone
* `default["openstack-compute"]["service_role"]` - User role used by nova when interacting with keystone
* `default["openstack-compute"]["floating_cmd"]` - Path to the `nova-manage floating create` wrapper script.
* `default["openstack-compute"]["pki"]["signing_dir"]` - Defaults to `/tmp/nova-signing-dir`. Directory where `auth_token` middleware writes certificate
* `default["openstack-compute"]["config"]["volume_api_class"]` - API Class used for Volume support
* `default["openstack-compute"]["compute"]["api"]["protocol"]` - Protocol used for the OS API
* `default["openstack-compute"]["compute"]["api"]["port"]` - Port on which OS API runs
* `default["openstack-compute"]["compute"]["api"]["version"]` - Version of the OS API used
* `default["openstack-compute"]["compute"]["adminURL"]` - URL used to access the OS API for admin functions
* `default["openstack-compute"]["compute"]["internalURL"]` - URL used to access the OS API for user functions from an internal network
* `default["openstack-compute"]["compute"]["publicURL"]` - URL used to access the OS API for user functions from an external network
* `default["openstack-compute"]["config"]["availability_zone"]` - Nova availability zone.  Usually set at the node level to place a compute node in another az
* `default["openstack-compute"]["config"]["default_schedule_zone"]` - The availability zone to schedule instances in when no az is specified in the request
* `default["openstack-compute"]["config"]["force_raw_images"]` - Convert all images used as backing files for instances to raw (we default to false)
* `default["openstack-compute"]["config"]["allow_same_net_traffic"]` - Disable security groups for internal networks (we default to true)
* `default["openstack-compute"]["config"]["osapi_max_limit"]` - The maximum number of items returned in a single response from a collection resource (default is 1000)
* `default["openstack-compute"]["config"]["cpu_allocation_ratio"]` - Virtual CPU to Physical CPU allocation ratio (default 16.0)
* `default["openstack-compute"]["config"]["ram_allocation_ratio"]` - Virtual RAM to Physical RAM allocation ratio (default 1.5)
* `default["openstack-compute"]["config"]["snapshot_image_format"]` - Snapshot image format (valid options are : raw, qcow2, vmdk, vdi [we default to qcow2]).
* `default["openstack-compute"]["config"]["start_guests_on_host_boot"]` - Whether to restart guests when the host reboots
* `default["openstack-compute"]["config"]["resume_guests_state_on_host_boot"]` - Whether to start guests that were running before the host rebooted
* `default["openstack-compute"]["api"]["signing_dir"]` - Keystone PKI needs a location to hold the signed tokens
* `default["openstack-compute"]["api"]["signing_dir"]` - Keystone PKI needs a location to hold the signed tokens

Networking Attributes
---------------------

Basic networking configuration is controlled with the following attributes:

* `default["openstack-compute"]["network"]["network_manager"]` - Defaults to "nova.network.manager.FlatDHCPManager". Set to "nova.network.manager.VlanManager" to configure VLAN Networking.
* `default["openstack-compute"]["network"]["fixed_range"]` - The CIDR for the network that VMs will be assigned to. In the case of VLAN Networking, this should be the network in which all VLAN networks that tenants are assigned will fit.
* `default["openstack-compute"]["network"]["dmz_cidr"]` - A CIDR for the range of IP addresses that will NOT be SNAT'ed by the nova network controller
* `default["openstack-compute"]["network"]["public_interface"]` - Defaults to eth0. Refers to the network interface used for VM addresses in the `fixed_range`.
* `default["openstack-compute"]["network"]["vlan_interface"]` - Defaults to eth0. Refers to the network interface used for VM addresses when VMs are assigned in a VLAN subnet.

You can have the cookbook automatically create networks in Nova for you by adding a Hash to the `default["openstack-compute"]["networks"]` Array.
**Note**: The `nova::nova-setup` recipe contains the code that creates these pre-defined networks.

Each Hash must contain the following keys:

* `ipv4_cidr` - The CIDR representation of the subnet. Supplied to the nova-manage network create command as `--fixed_ipv4_range`
* `label` - A name for the network

In addition to the above required keys in the Hash, the below keys are optional:

* `num_networks` - Passed as-is to `nova-manage network create` as the `--num_networks` option. This overrides the default `num_networks` nova.conf value.
* `network_size` - Passed as-is to `nova-manage network create` as the `--network_size` option. This overrides the default `network_size` nova.conf value.
* `bridge` - Passed as-is to `nova-manage network create` as the `--bridge` option.
* `bridge_interface` -- Passed as-is to `nova-manage network create` as the `--bridge_interface` option. This overrides the default `vlan_interface` nova.conf value.
* `dns1` - Passed as-is to `nova-manage network create` as the `--dns1` option.
* `dns2` - Passed as-is to `nova-manage network create` as the `--dns2` option.
* `multi_host` - Passed as-is to `nova-manage network create` as the `--multi_host` option. Values should be either 'T' or 'F'
* `vlan` - Passed as-is to `nova-manage network create` as the `--vlan` option. Should be the VLAN tag ID.

By default, the `default["openstack-compute"]["networks"]` array has two networks:

* `default["openstack-compute"]["networks"]["public"]["label"]` - Network label to be assigned to the public network on creation
* `default["openstack-compute"]["networks"]["public"]["ipv4_cidr"]` - Network to be created (in CIDR notation, e.g., 192.168.100.0/24)
* `default["openstack-compute"]["networks"]["public"]["num_networks"]` - Number of networks to be created
* `default["openstack-compute"]["networks"]["public"]["network_size"]` - Number of IP addresses to be used in this network
* `default["openstack-compute"]["networks"]["public"]["bridge"]` - Bridge to be created for accessing the VM network (e.g., br100)
* `default["openstack-compute"]["networks"]["public"]["bridge_dev"]` - Physical device on which the bridge device should be attached (e.g., eth2)
* `default["openstack-compute"]["networks"]["public"]["dns1"]` - DNS server 1
* `default["openstack-compute"]["networks"]["public"]["dns2"]` - DNS server 2

* `default["openstack-compute"]["networks"]["private"]["label"]` - Network label to be assigned to the private network on creation
* `default["openstack-compute"]["networks"]["private"]["ipv4_cidr"]` - Network to be created (in CIDR notation e.g., 192.168.200.0/24)
* `default["openstack-compute"]["networks"]["private"]["num_networks"]` - Number of networks to be created
* `default["openstack-compute"]["networks"]["private"]["network_size"]` - Number of IP addresses to be used in this network
* `default["openstack-compute"]["networks"]["private"]["bridge"]` - Bridge to be created for accessing the VM network (e.g., br200)
* `default["openstack-compute"]["networks"]["private"]["bridge_dev"]` - Physical device on which the bridge device should be attached (e.g., eth3)

VNC Configuration Attributes
----------------------------

Requires [network_addr](https://gist.github.com/jtimberman/1040543) Ohai plugin.

* `default["openstack-compute"]["xvpvnc_proxy"]["service_port"]` - Port on which XvpVNC runs
* `default["openstack-compute"]["xvpvnc_proxy"]["bind_interface"]` - Determine the interface's IP address to bind to
* `default["openstack-compute"]["novnc_proxy"]["service_port"]` - Port on which NoVNC runs
* `default["openstack-compute"]["novnc_proxy"]["bind_interface"]` - Determine the interface's IP address to bind to

Libvirt Configuration Attributes
---------------------------------

* `default["openstack-compute"]["libvirt"]["virt_type"]` - What hypervisor software layer to use with libvirt (e.g., kvm, qemu)
* `default["openstack-compute"]["libvirt"]["bind_interface"]` - Determine the interface's IP address (used for VNC).  IP address on the hypervisor that libvirt listens for VNC requests on, and IP address on the hypervisor that libvirt exposes for VNC requests on.
* `default["openstack-compute"]["libvirt"]["auth_tcp"]` - Type of authentication your libvirt layer requires
* `default["openstack-compute"]["libvirt"]["ssh"]["private_key"]` - Private key to use if using SSH authentication to your libvirt layer
* `default["openstack-compute"]["libvirt"]["ssh"]["public_key"]` - Public key to use if using SSH authentication to your libvirt layer

Scheduler Configuration Attributes
----------------------------------

* `default["openstack-compute"]["scheduler"]["scheduler_driver"]` - the scheduler driver to use
NOTE: The filter scheduler currently does not work with ec2.
* `default["openstack-compute"]["scheduler"]["default_filters"]` - a list of filters enabled for schedulers that support them.

Syslog Configuration Attributes
-------------------------------

* `default["openstack-compute"]["syslog"]["use"]` - Should nova log to syslog?
* `default["openstack-compute"]["syslog"]["facility"]` - Which facility nova should use when logging in python style (for example, `LOG_LOCAL1`)
* `default["openstack-compute"]["syslog"]["config_facility"]` - Which facility nova should use when logging in rsyslog style (for example, local1)

OSAPI Compute Extentions
------------------------

* `default["openstack-compute"]["plugins"]` - Array of osapi compute exntesions to add to nova

Testing
=====

This cookbook is using [ChefSpec](https://github.com/acrmp/chefspec) for
testing. Run the following before commiting. It will run your tests,
and check for lint errors.

    $ ./run_tests.bash

License and Author
==================

Author:: Justin Shepherd (<justin.shepherd@rackspace.com>)
Author:: Jason Cannavale (<jason.cannavale@rackspace.com>)
Author:: Ron Pedde (<ron.pedde@rackspace.com>)
Author:: Joseph Breu (<joseph.breu@rackspace.com>)
Author:: William Kelly (<william.kelly@rackspace.com>)
Author:: Darren Birkett (<darren.birkett@rackspace.co.uk>)
Author:: Evan Callicoat (<evan.callicoat@rackspace.com>)
Author:: Matt Ray (<matt@opscode.com>)
Author:: Jay Pipes (<jaypipes@att.com>)
Author:: John Dewey (<jdewey@att.com>)

Copyright 2012, Rackspace US, Inc.
Copyright 2012, Opscode, Inc.
Copyright 2012-2013, AT&T Services, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
