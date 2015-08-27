Description
===========

This cookbook installs the OpenStack Compute service **Nova** as part of the OpenStack reference deployment Chef for OpenStack. The https://github.com/mattray/openstack-chef-repo contains documentation for using this cookbook in the context of a full OpenStack deployment. Nova is currently installed from packages.

http://nova.openstack.org

Requirements
============

Chef 0.10.0 or higher required (for Chef environment use).

Cookbooks
---------

The following cookbooks are dependencies:

* openstack-common
* openstack-identity
* openstack-image
* openstack-network
* selinux (Fedora)
* python

Usage
=====

api-ec2
----
- Includes recipe `nova-common`
- Installs AWS EC2 compatible API and configures the service and endpoints in keystone

api-metadata
----
- Includes recipe `nova-common`
- Installs the nova metadata package

api-os-compute
----
- Includes recipe `nova-common`
- Installs OS API and configures the service and endpoints in keystone

client
----
- Install the nova client packages

compute
----
- Includes recipes `nova-common`, `api-metadata`, `network`
- Installs nova-compute service

libvirt
----
- Installs libvirt, used by nova compute for management of the virtual machine environment

libvirt_rbd
----
- Prepares the compute node for interaction with a Ceph cluster for block storage (RBD)
- Depends on `ceph::_common`, `ceph::install`, and `ceph::conf` for packages and cluster connectivity (i.e. a proper `/etc/ceph/ceph.conf`)

network
----
- Includes recipe `nova-common`
- Installs nova network service

nova-cert
----
- Installs nova-cert service

nova-common
----
- May include recipe `selinux` (Fedora)
- Builds the basic nova.conf config file with details of the rabbitmq, mysql, glance and keystone servers

nova-setup
----
- Includes recipes `nova-common`
- Sets up the nova networks with `nova-manage`

scheduler
----
- Includes recipe `nova-common`
- Installs nova scheduler service

vncproxy
----
- Includes recipe `nova-common`
- Installs and configures the vncproxy service for console access to VMs

serialproxy
----
- Includes recipe `nova-common`
- Installs and configures the serialproxy service for serial console access to VMs

Attributes
==========

Openstack Compute attributes are in the attribute namespace ["openstack"]["compute"].

* `openstack["compute"]["identity_service_chef_role"]` - The name of the Chef role that sets up the Keystone Service API
* `openstack["compute"]["user"]` - User nova services run as
* `openstack["compute"]["group"]` - Group nova services run as
* `openstack["compute"]["db"]["username"]` - Username for nova database access
* `openstack["compute"]["service_tenant_name"]` - Tenant name used by nova when interacting with keystone
* `openstack["compute"]["service_user"]` - User name used by nova when interacting with keystone
* `openstack["compute"]["service_role"]` - User role used by nova when interacting with keystone
* `openstack["compute"]["floating_cmd"]` - Path to the `nova-manage floating create` wrapper script.
* `openstack["compute"]["ec2_workers"]` - Number of ec2 workers
* `openstack["compute"]["osapi_compute_workers"]` - Number of api workers
* `openstack["compute"]["metadata_workers"]` - Number of metadata workders
* `openstack["compute"]["config"]["volume_api_class"]` - API Class used for Volume support
* `openstack['compute']['driver'] = Driver to use for controlling virtualization
* `openstack['compute']['manager'] = Full class name for the Manager for compute
* `openstack['compute']['default_ephemeral_format'] = The default format an ephemeral_volume will be formatted with on creation
* `openstack['compute']['preallocate_images'] = VM image preallocation mode
* `openstack['compute']['use_cow_images'] = Whether to use cow images
* `openstack['compute']['vif_plugging_is_fatal'] = Fail instance boot if vif plugging fails
* `openstack['compute']['vif_plugging_timeout'] = Number of seconds to wait for neutron vif plugging events to arrive before continuing or failing
* `openstack['compute']['ssl_only'] = Disallow non-encrypted connections
* `openstack['compute']['cert'] = SSL certificate file
* `openstack['compute']['key'] = SSL key file (if separate from cert)
* `openstack['compute']['dbsync_timeout']` - Set dbsync command timeout value
* `openstack["compute"]["compute"]["api"]["protocol"]` - Protocol used for the OS API
* `openstack["compute"]["compute"]["api"]["port"]` - Port on which OS API runs
* `openstack["compute"]["compute"]["api"]["version"]` - Version of the OS API used
* `openstack["compute"]["compute"]["adminURL"]` - URL used to access the OS API for admin functions
* `openstack["compute"]["compute"]["internalURL"]` - URL used to access the OS API for user functions from an internal network
* `openstack["compute"]["compute"]["publicURL"]` - URL used to access the OS API for user functions from an external network
* `openstack["compute"]["compute"]["dnsmasq_config_file"]` - Override the default dnsmasq settings with this file
* `openstack["compute"]["config"]["availability_zone"]` - Nova availability zone.  Usually set at the node level to place a compute node in another az
* `openstack["compute"]["config"]["default_schedule_zone"]` - The availability zone to schedule instances in when no az is specified in the request
* `openstack["compute"]["config"]["force_raw_images"]` - Convert all images used as backing files for instances to raw (we default to false)
* `openstack["compute"]["config"]["allow_same_net_traffic"]` - Disable security groups for internal networks (we default to true)
* `openstack["compute"]["config"]["osapi_max_limit"]` - The maximum number of items returned in a single response from a collection resource (default is 1000)
* `openstack["compute"]["config"]["osapi_compute_link_prefix"]` - Base URL that will be presented to users in links to the OpenStack Compute API (default is nil)
* `openstack["compute"]["config"]["osapi_glance_link_prefix"]` - Base URL that will be presented to users in links to glance resources(default is nil)
* `openstack["compute"]["config"]["cpu_allocation_ratio"]` - Virtual CPU to Physical CPU allocation ratio (default 16.0)
* `openstack["compute"]["config"]["ram_allocation_ratio"]` - Virtual RAM to Physical RAM allocation ratio (default 1.5)
* `openstack["compute"]["config"]["snapshot_image_format"]` - Snapshot image format (valid options are : raw, qcow2, vmdk, vdi [we default to qcow2]).
* `openstack["compute"]["config"]["start_guests_on_host_boot"]` - Whether to restart guests when the host reboots
* `openstack["compute"]["config"]["resume_guests_state_on_host_boot"]` - Whether to start guests that were running before the host rebooted
* `openstack["compute"]["config"]["disk_allocation_ratio"]` - Virtual disk to physical disk allocation ratio (default 1.0)
* `openstack["compute"]["config"]["allow_resize_to_same_host"]` - Allow destination machine to match source for resize. Useful when testing in single-host environments (default is false)
* `openstack["compute"]["config"]["resize_confirm_window"]` -  Automatically confirm resizes after N seconds, Set to 0 to disable (default is 0)
* `openstack["compute"]["config"]["reserved_host_memory_mb"]` - Amount of disk in MB to reserve for the host (default is 512)
* `openstack["compute"]["config"]["disk_cachemodes"]` - Cachemodes to use for different disk types e.g: "file=directsync,block=none".  Valid cache values are "default", "none", "writethrough", "writeback", "directsync" and "unsafe".
* `openstack["compute"]["config"]["live_migration_retry_count"]` - Number of 1 second retries needed in live_migration
* `openstack["compute"]["config"]["flat_injected"]` - Whether to attempt to inject network setup into guest. Used by config_drive support.
* `openstack["compute"]["config"]["config_drive_format"]` - Config drive format.
* `openstack["compute"]["api"]["signing_dir"]` - Keystone PKI needs a location to hold the signed tokens
* `openstack["compute"]["api"]["signing_dir"]` - Keystone PKI needs a location to hold the signed tokens
* `openstack["compute"]["rpc_thread_pool_size"]` - Size of RPC thread pool (default 64)
* `openstack["compute"]["rpc_conn_pool_size"]` - Size of RPC connection pool (default 30)
* `openstack["compute"]["rpc_response_timeout"]` - Seconds to wait for a response from call or multicall (default 60)
* `openstack['compute']['api']['auth']['version']` - Select v2.0 or v3.0. Default v2.0. The auth API version used to interact with identity service.
* `openstack['compute']['api']['auth']['memcached_servers']` - A list of memcached server(s) for caching
* `openstack['compute']['api']['auth']['memcache_security_strategy']` - Whether token data should be authenticated or authenticated and encrypted. Acceptable values are MAC or ENCRYPT.
* `openstack['compute']['api']['auth']['memcache_secret_key']` - This string is used for key derivation.
* `openstack['compute']['api']['auth']['hash_algorithms']` - Hash algorithms to use for hashing PKI tokens.
* `openstack['compute']['api']['auth']['cafile']` - A PEM encoded Certificate Authority to use when verifying HTTPs connections.
* `openstack['compute']['api']['auth']['insecure']` - Whether to allow the client to perform insecure SSL (https) requests.
* `openstack['compute']['conductor']['workers']` = Number of conductor workers


MQ attributes
-------------
* `openstack["compute"]["mq"]["service_type"]` - Select qpid or rabbitmq. default rabbitmq
TODO: move rabbit parameters under openstack["compute"]["mq"]
* `openstack["compute"]["rabbit"]["username"]` - Username for nova rabbit access
* `openstack["compute"]["rabbit"]["vhost"]` - The rabbit vhost to use
* `openstack["compute"]["rabbit"]["port"]` - The rabbit port to use
* `openstack["compute"]["rabbit"]["host"]` - The rabbit host to use (must set when `openstack["compute"]["rabbit"]["ha"]` false).
* `openstack["compute"]["rabbit"]["ha"]` - Whether or not to use rabbit ha
* `openstack["compute"]["rabbit"]["heartbeat_timeout_threshold"]` - Number of seconds after which the Rabbit broker is considered down if heartbeat's keep-alive fails (0 disable the heartbeat)
* `openstack["compute"]["rabbit"]["heartbeat_rate"]` - How often times during the heartbeat_timeout_threshold we check the heartbeat

* `openstack["compute"]["mq"]["qpid"]["host"]` - The qpid host to use
* `openstack["compute"]["mq"]["qpid"]["port"]` - The qpid port to use
* `openstack["compute"]["mq"]["qpid"]["qpid_hosts"]` - Qpid hosts. TODO. use only when ha is specified.
* `openstack["compute"]["mq"]["qpid"]["username"]` - Username for qpid connection
* `openstack["compute"]["mq"]["qpid"]["password"]` - Password for qpid connection
* `openstack["compute"]["mq"]["qpid"]["sasl_mechanisms"]` - Space separated list of SASL mechanisms to use for auth
* `openstack["compute"]["mq"]["qpid"]["reconnect_timeout"]` - The number of seconds to wait before deciding that a reconnect attempt has failed.
* `openstack["compute"]["mq"]["qpid"]["reconnect_limit"]` - The limit for the number of times to reconnect before considering the connection to be failed.
* `openstack["compute"]["mq"]["qpid"]["reconnect_interval_min"]` - Minimum number of seconds between connection attempts.
* `openstack["compute"]["mq"]["qpid"]["reconnect_interval_max"]` - Maximum number of seconds between connection attempts.
* `openstack["compute"]["mq"]["qpid"]["reconnect_interval"]` - Equivalent to setting qpid_reconnect_interval_min and qpid_reconnect_interval_max to the same value.
* `openstack["compute"]["mq"]["qpid"]["heartbeat"]` - Seconds between heartbeat messages sent to ensure that the connection is still alive.
* `openstack["compute"]["mq"]["qpid"]["protocol"]` - Protocol to use. Default tcp.
* `openstack["compute"]["mq"]["qpid"]["tcp_nodelay"]` - Disable the Nagle algorithm. default disabled.

Glance Attributes
-----------------

* `openstack["compute"]["image"]["glance_api_insecure"]` - If True, this indicates that glance-api allows the client to perform insecure SSL(https) requests, this should be the same as the setting in the glance-api service.
* `openstack["compute"]["image"]["ssl"]["ca_file"]` - CA certificate file to use to verify connecting clients.
* `openstack["compute"]["image"]["ssl"]["cert_file"]` - Certificate file to use when starting the server securely.
* `openstack["compute"]["image"]["ssl"]["key_file"]` - Private key file to use when starting the server securely.

Cinder Attributes
-----------------

* `openstack["compute"]["block-storage"]["cinder_ca_certificates_file"]` - Location of ca certificates file to use for cinder client requests.
* `openstack["compute"]["block-storage"]["cinder_api_insecure"]` - Allow to perform insecure SSL requests to cinder.
* `openstack["compute"]["block-storage"]["cinder_catalog_info"]` - Info to match when looking for cinder in the service catalog.

Networking Attributes
---------------------

Basic networking configuration is controlled with the following attributes:

* `openstack["compute"]["network"]["network_manager"]` - Defaults to "nova.network.manager.FlatDHCPManager". Set to "nova.network.manager.VlanManager" to configure VLAN Networking.
* `openstack["compute"]["network"]["dmz_cidr"]` - A CIDR for the range of IP addresses that will NOT be SNAT'ed by the nova network controller
* `openstack["compute"]["network"]["public_interface"]` - Defaults to eth0. Refers to the network interface used for VM addresses`.
* `openstack["compute"]["network"]["vlan_interface"]` - Defaults to eth0. Refers to the network interface used for VM addresses when VMs are assigned in a VLAN subnet.
* `openstack["compute"]["network"]["auto_assign_floating_ip"]` - Defaults to false. Autoassigning floating ip to VM, this should be only for nova network.
* `openstack["compute"]["network"]["force_dhcp_release"]` - If True, send a dhcp release on instance termination. (Default is false on "fedora", "redhat", "centos")
* `openstack["compute"]["network"]["use_ipv6"]` - If True, use ipv6 support.
* `openstack["compute"]["network"]["neutron"]["api_insecure"]` - If True, this indicates that neutron-api allows the client to perform insecure SSL (https) requests. This should be the same as the setting in the neutron api service.

You can have the cookbook automatically create networks in Nova for you by adding a Hash to the `openstack["compute"]["networks"]` Array.
**Note**: The `openstack-compute::nova-setup` recipe contains the code that creates these pre-defined networks.

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

By default, the `openstack["compute"]["networks"]` array has two networks:

* `openstack["compute"]["networks"]["public"]["label"]` - Network label to be assigned to the public network on creation
* `openstack["compute"]["networks"]["public"]["ipv4_cidr"]` - Network to be created (in CIDR notation, e.g., 192.168.100.0/24)
* `openstack["compute"]["networks"]["public"]["num_networks"]` - Number of networks to be created
* `openstack["compute"]["networks"]["public"]["network_size"]` - Number of IP addresses to be used in this network
* `openstack["compute"]["networks"]["public"]["bridge"]` - Bridge to be created for accessing the VM network (e.g., br100)
* `openstack["compute"]["networks"]["public"]["bridge_dev"]` - Physical device on which the bridge device should be attached (e.g., eth2)
* `openstack["compute"]["networks"]["public"]["dns1"]` - DNS server 1
* `openstack["compute"]["networks"]["public"]["dns2"]` - DNS server 2

* `openstack["compute"]["networks"]["private"]["label"]` - Network label to be assigned to the private network on creation
* `openstack["compute"]["networks"]["private"]["ipv4_cidr"]` - Network to be created (in CIDR notation e.g., 192.168.200.0/24)
* `openstack["compute"]["networks"]["private"]["num_networks"]` - Number of networks to be created
* `openstack["compute"]["networks"]["private"]["network_size"]` - Number of IP addresses to be used in this network
* `openstack["compute"]["networks"]["private"]["bridge"]` - Bridge to be created for accessing the VM network (e.g., br200)
* `openstack["compute"]["networks"]["private"]["bridge_dev"]` - Physical device on which the bridge device should be attached (e.g., eth3)

Libvirt Configuration Attributes
---------------------------------

* `openstack["compute"]["libvirt"]["virt_type"]` - What hypervisor software layer to use with libvirt (e.g., kvm, qemu)
* `openstack["compute"]["libvirt"]["volume_backend"]` - What block storage backend to use with libvirt (e.g. rbd)
* `openstack["compute"]["libvirt"]["auth_tcp"]` - Type of authentication your libvirt layer requires
* `openstack["compute"]["libvirt"]["ssh"]["private_key"]` - Private key to use if using SSH authentication to your libvirt layer
* `openstack["compute"]["libvirt"]["ssh"]["public_key"]` - Public key to use if using SSH authentication to your libvirt layer
* `openstack["compute"]["libvirt"]["max_clients"]` - Maximum number of concurrent client connections to allow over all sockets combined. (default: 20)
* `openstack["compute"]["libvirt"]["max_workers"]` - Maximum number of workers spawned, typically equal to max_clients. (default: 20)
* `openstack["compute"]["libvirt"]["max_requests"]` - Total global limit on concurrent RPC calls. Should be at least as large as max_workers. (default: 20)
* `openstack["compute"]["libvirt"]["max_client_requests"]` - Limit on concurrent requests from a single client connection. (default: 5)
* `openstack["compute"]["libvirt"]["libvirt_inject_key"]` - Inject the ssh public key at boot time, without an agent. (default: true)
* `openstack["compute"]["libvirt"]["libvirt_inject_password"]` - Inject the admin password at boot time, without an agent. (default: false)
* `openstack["compute"]["libvirt"]["libvirt_inject_partition"]` - The partition to inject to : -2 => disable, -1 => inspect (libguestfs only), 0 => not partitioned, >0 => partition number. (default: -2)
* `openstack["compute"]["libvirt"]["images_type"]` - How to store local images (ephemeral disks): raw, qcow2, lvm, rbd, or default
* `openstack["compute"]["libvirt"]["volume_group"]` - When images_type is lvm: volume group to use
* `openstack["compute"]["libvirt"]["sparse_logical_volumes"]` - When images_type is lvm: use sparse logical volumes
* `openstack["compute"]["libvirt"]["unix_sock_rw_perms"]` - Set the UNIX socket permissions for the R/W socket. This is used for full management of VMs.
* `openstack["compute"]["libvirt"]["live_migration_bandwidth"]` - Maximum bandwidth to be used during migration, in Mbps.
* `openstack["compute"]["libvirt"]["live_migration_flag"]` - Migration flags to be set for live migration.
* `openstack["compute"]["libvirt"]["block_migration_flag"]` - Migration flags to be set for block migration.
* `openstack["compute"]["libvirt"]["live_migration_uri"]` - Migration target URI (any included "%s" is replaced with the migration target hostname).
* `openstack["compute"]["libvirt"]["rbd"]["glance"]["pool"]` - When images_type is rbd: use this RBD pool for images
* `openstack["compute"]["libvirt"]["rbd"]["cinder"]["pool"]` - When images_type is rbd: use this RBD pool for volumes
* `openstack["compute"]["libvirt"]["rbd"]["nova"]["pool"]` - When images_type is rbd: use this RBD pool for instances
* `openstack["compute"]["libvirt"]["rbd"]["ceph_conf"]` - When images_type is rbd: use this ceph.conf
* `openstack["compute"]["libvirt"]["rbd"]["cinder"]["user"]` - The cephx user used for accessing the RBD pool used for block storage. (Which pool to use is passed by cinder when nova-compute is instructed to mount a volume.)
* `openstack["compute"]["libvirt"]["rbd"]["cinder"]["secret_uuid"]` - A shared secret between cinder and libvirt.  It should be the same as the secret_uuid that is defined in block-storage.
* `openstack["compute"]["libvirt"]["rng_dev_path"]` - A path to a device that will be used as source of entropy on the host. Permitted options are: /dev/random or /dev/hwrng (string value)

Bare Metal Configuration Attributes
-----------------------------------

* `openstack['compute']['scheduler']['use_baremetal_filters']` Boolean that decides whether to use baremetal_scheduler_default_filters or not.
  If this attribute is set to true, the following attributes will be overwritten:
  `openstack['compute']['driver']`
  `openstack['compute']['manager']`
  `openstack['compute']['scheduler']['scheduler_host_manager']`
  `openstack['compute']['config']['ram_allocation_ratio']`
  `openstack['compute']['config']['reserved_host_memory_mb']`
* `openstack['compute']['scheduler']['baremetal_default_filters']` A list of filters enabled for baremetal schedulers that support them.

Keymgr Configuration Attributes
-------------------------------

* `openstack["compute"]["keymgr"]["api_class"] - the full class name of the key manager API class.
* `openstack["compute"]["keymgr"]["fixed_key"] - the fixed key returned by key manager, specified in hex (string value).

Scheduler Configuration Attributes
----------------------------------

* `openstack["compute"]["scheduler"]["scheduler_manager"]` - the scheduler manager to use
* `openstack["compute"]["scheduler"]["scheduler_driver"]` - the scheduler driver to use
NOTE: The filter scheduler currently does not work with ec2.
* `openstack["compute"]["scheduler"]["available_filters"]` - Filter classes available to the scheduler which may be specified more than once.
* `openstack["compute"]["scheduler"]["default_filters"]` - a list of filters enabled for schedulers that support them.

Syslog Configuration Attributes
-------------------------------

* `openstack["compute"]["syslog"]["use"]` - Should nova log to syslog?
* `openstack["compute"]["syslog"]["facility"]` - Which facility nova should use when logging in python style (for example, `LOG_LOCAL1`)
* `openstack["compute"]["syslog"]["config_facility"]` - Which facility nova should use when logging in rsyslog style (for example, local1)

OSAPI Compute Extentions
------------------------

* `openstack["compute"]["plugins"]` - Array of osapi compute exntesions to add to nova

Miscellaneous Options
---------------------

Arrays whose elements will be copied exactly into the respective config files (contents e.g. ['option1=value1', 'option2=value2']).

* `openstack["compute"]["misc_nova"]` - Array of bare options for `nova.conf`.
* `openstack["compute"]["misc_paste"]` - Array of bare options for `api-paste.ini`

EC2 Configuration Attributes
----------------------------

* `openstack["compute"]["enabled_apis"]` - Which apis have been enabled in nova compute, only for ec2 and osapi_compute. For metadata, include the api-metadata recipe.

Notification Attributes
-----------------------

* `openstack["compute"]["metering"]`- Boolean that indicates whether to enable the metering attributes with sensible defaults. Default is false.
* `openstack["compute"]["config"]["notification_drivers"]`- An array of drivers to handle sending notifications.
* `openstack["compute"]["config"]["instance_usage_audit"]`- Boolean that indicates whether to generate intance usage audits.
* `openstack["compute"]["config"]["instance_usage_audit_period"]`- Time period to generate instance usages for.  Time period must be "hour", "day", "month" or "year".
* `openstack["compute"]["config"]["notify_on_state_change"]`- If set, send compute.instance.update notifications on instance state changes.  Valid values are None, "vm_state" or "vm_and_task_state".
* `openstack["compute"]["config"]["notification_topics"]`- AMQP topic used for OpenStack notifications.

When enabling nova metering with ceilometer, the notification configuration
properties need to be set to values that are different from the default values
used when metering is off. In order to facilitate setting all those
notification properties, the cookbook includes the `openstack["compute"]["metering"]`
attribute which when set to `true` will automatically set all notification
properties to the suggested defaults.

One of the notification_drivers that is set when metering is on comes from
ceilometer. In order for the notification driver to be available, make sure
the `os-telemetry-agent-compute` role (or the openstack-telemetry::agent-compute recipe)
are set on this node.

Monitor Attributes
-----------------------

* `openstack["compute"]["config"]["compute_available_monitors"]`- Monitor classes available to the compute.
* `openstack["compute"]["config"]["compute_monitors"]`- An array of monitors that can be used for getting compute metrics.

VMware Configuration Attributes
-------------------------------

* `openstack['compute']['vmware']['secret_name']` - VMware databag secret name
* `openstack['compute']['vmware']['host_ip']` - URL for connection to VMware ESX/VC host. (string value)
* `openstack['compute']['vmware']['host_username']` - Username for connection to VMware ESX/VC host. (string value)
* `openstack['compute']['vmware']['cluster_name']` - Name of a VMware Cluster ComputeResource. Used only if compute_driver is vmwareapi.VMwareVCDriver. (multi valued)
* `openstack['compute']['vmware']['datastore_regex']` - Regex to match the name of a datastore. (string value)
* `openstack['compute']['vmware']['task_poll_interval']` - The interval used for polling of remote tasks. (floating point value, default 0.5)
* `openstack['compute']['vmware']['api_retry_count']` - The number of times we retry on failures, e.g., socket error, etc. (integer value, default 10)
* `openstack['compute']['vmware']['vnc_port']` - VNC starting port (integer value, default 5900)
* `openstack['compute']['vmware']['vnc_port_total']` - Total number of VNC ports (integer value, default 10000)
* `openstack['compute']['vmware']['use_linked_clone']` - Whether to use linked clone (boolean value, default true)
* `openstack['compute']['vmware']['vlan_interface']` - Physical ethernet adapter name for vlan networking (string value, default vmnic0)
* `openstack['compute']['vmware']['wsdl_location']` - Optional VIM Service WSDL Location, you must specify this location of the WSDL files when you try to connect vSphere vCenter versions 5.0 and earlier.
* `openstack['compute']['vmware']['maximum_objects']` - The maximum number of ObjectContent data objects that should be returned in a single result. (integer value, default 100)
* `openstack['compute']['vmware']['integration_bridge']` - Name of Integration Bridge (string value, default br-int)

Upgrade levels Attribute
------------------------
* `openstack['openstack']['compute']['upgrade_levels']` - The RPC version numbers or release name alias

Docker configuration Attributes
-------------------------------

* `['openstack']['compute']['docker']['enable']` - Mark this as true to make compute docker type and use nova docker driver as compute driver. Docker computes are supported only in Ubuntu and Rhel
* `['openstack']['compute']['docker']['driver']` - The nova docker driver that will be configured in a docker type compute
* `['openstack']['compute']['platform']['docker_build_pkgs']` - Additoinal packages required for nova docker driver build and installation from git source
* `['openstack']['compute']['docker']['pip_build_pkgs']` - Additional python packages required for nova docker driver build and installation from git source
* `['openstack']['compute']['docker']['github']['repository']` - github repository from which nova-docker source will be downloaded
* `['openstack']['compute']['docker']['github']['branch']` - github branch from which nova-docker source will be downloaded. Default is master
* `['openstack']['compute']['docker']['filter_source_path']` - Relative path to docker filter files in nova-docker source which will be cloned from git repo
* `['openstack']['compute']['docker']['service_sock']` - Path to docker service sock file
* `['openstack']['compute']['docker']['service_sock_mode']` - Permission level to be assigned to docker sock file
* `['openstack']['compute']['docker']['group']` - Docker group which will be created and added with openstack compute user

The following attributes are defined in attributes/default.rb of the common cookbook, but are documented here due to their relevance:

* `openstack['endpoints']['compute-compute api-bind']['host']` - The IP address to bind the compute api service to
* `openstack['endpoints']['compute-compute api-bind']['port']` - The port to bind the compute api service to
* `openstack['endpoints']['compute-compute api-bind']['bind_interface']` - The interface name to bind the compute api service to

* `openstack['endpoints']['compute-ec2-api-bind']['host']` - The IP address to bind the ec2 api service to
* `openstack['endpoints']['compute-ec2-api-bind']['port']` - The port to bind the ec2 api service to
* `openstack['endpoints']['compute-ec2-api-bind']['bind_interface']` - The interface name to bind the ec2 api service to

* `openstack['endpoints']['compute-ec2-admin-bind']['host']` - The IP address to bind the ec2 admin api service to
* `openstack['endpoints']['compute-ec2-admin-bind']['port']` - The port to bind the ec2 admin api service to
* `openstack['endpoints']['compute-ec2-admin-bind']['bind_interface']` - The interface name to bind the ec2 admin api service to

* `openstack['endpoints']['compute-xvpvnc-bind']['host']` - The IP address to bind the xvpvnc service to
* `openstack['endpoints']['compute-xvpvnc-bind']['port']` - The port to bind the xvpvnc service to
* `openstack['endpoints']['compute-xvpvnc-bind']['bind_interface']` - The interface name to bind the xvpvnc service to

* `openstack['endpoints']['compute-novnc-bind']['host']` - The IP address to bind the novnc service to
* `openstack['endpoints']['compute-novnc-bind']['port']` - The port to bind the novnc service to
* `openstack['endpoints']['compute-novnc-bind']['bind_interface']` - The interface name to bind the novnc service to

* `openstack['endpoints']['compute-vnc-bind']['host']` - The IP address to bind the vnc service to
* `openstack['endpoints']['compute-vnc-bind']['bind_interface']` - The interface name to bind the vnc service to

* `openstack['endpoints']['compute-vnc-proxy-bind']['host']` - The IP address to bind the vnc proxy service to
* `openstack['endpoints']['compute-vnc-proxy-bind']['bind_interface']` - The interface name to bind the vnc proxy service to

If the value of the 'bind_interface' attribute is non-nil, then the service will be bound to the first IP address on that interface.  If the value of the 'bind_interface' attribute is nil, then the service will be bound to the IP address specified in the host attribute.

Testing
=====

Please refer to the [TESTING.md](TESTING.md) for instructions for testing the cookbook.

Berkshelf
=====

Berks will resolve version requirements and dependencies on first run and
store these in Berksfile.lock. If new cookbooks become available you can run
`berks update` to update the references in Berksfile.lock. Berksfile.lock will
be included in stable branches to provide a known good set of dependencies.
Berksfile.lock will not be included in development branches to encourage
development against the latest cookbooks.

License and Author
==================

|                      |                                                    |
|:---------------------|:---------------------------------------------------|
| **Author**           |  Justin Shepherd (<justin.shepherd@rackspace.com>) |
| **Author**           |  Jason Cannavale (<jason.cannavale@rackspace.com>) |
| **Author**           |  Ron Pedde (<ron.pedde@rackspace.com>)             |
| **Author**           |  Joseph Breu (<joseph.breu@rackspace.com>)         |
| **Author**           |  William Kelly (<william.kelly@rackspace.com>)     |
| **Author**           |  Darren Birkett (<darren.birkett@rackspace.co.uk>) |
| **Author**           |  Evan Callicoat (<evan.callicoat@rackspace.com>)   |
| **Author**           |  Matt Ray (<matt@opscode.com>)                     |
| **Author**           |  Jay Pipes (<jaypipes@att.com>)                    |
| **Author**           |  John Dewey (<jdewey@att.com>)                     |
| **Author**           |  Kevin Bringard (<kbringard@att.com>)              |
| **Author**           |  Craig Tracey (<craigtracey@gmail.com>)            |
| **Author**           |  Sean Gallagher (<sean.gallagher@att.com>)         |
| **Author**           |  Ionut Artarisi (<iartarisi@suse.cz>)              |
| **Author**           |  JieHua Jin (<jinjhua@cn.ibm.com>)                 |
| **Author**           |  David Geng (<gengjh@cn.ibm.com>)                  |
| **Author**           |  Salman Baset (<sabaset@us.ibm.com>)               |
| **Author**           |  Chen Zhiwei (<zhiwchen@cn.ibm.com>)               |
| **Author**           |  Mark Vanderwiel (<vanderwl@us.ibm.com>)           |
| **Author**           |  Eric Zhou (<zyouzhou@cn.ibm.com>)                 |
| **Author**           |  Mathew Odden (<mrodden@us.ibm.com>)               |
|                      |                                                    |
| **Copyright**        |  Copyright (c) 2012-2013, Rackspace US, Inc.       |
| **Copyright**        |  Copyright (c) 2012-2013, Opscode, Inc.            |
| **Copyright**        |  Copyright (c) 2012-2013, AT&T Services, Inc.      |
| **Copyright**        |  Copyright (c) 2013, Craig Tracey                  |
| **Copyright**        |  Copyright (c) 2013-2014, SUSE Linux GmbH          |
| **Copyright**        |  Copyright (c) 2013-2014, IBM, Corp.               |

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
