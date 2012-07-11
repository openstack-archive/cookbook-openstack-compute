########################################################################
# Toggles - These can be overridden at the environment level
default["enable_monit"] = false  # OS provides packages
default["developer_mode"] = false  # we want secure passwords by default
########################################################################

default["nova"]["db"]["name"] = "nova"
default["nova"]["db"]["username"] = "nova"

default["nova"]["service_tenant_name"] = "service"
default["nova"]["service_user"] = "nova"
default["nova"]["service_role"] = "admin"

default["nova"]["services"]["api"]["scheme"] = "http"
default["nova"]["services"]["api"]["network"] = "public"
default["nova"]["services"]["api"]["port"] = 8774
default["nova"]["services"]["api"]["path"] = "/v2/%(tenant_id)s"

default["nova"]["services"]["ec2-admin"]["scheme"] = "http"
default["nova"]["services"]["ec2-admin"]["network"] = "public"
default["nova"]["services"]["ec2-admin"]["port"] = 8773
default["nova"]["services"]["ec2-admin"]["path"] = "/services/Admin"

default["nova"]["services"]["ec2-public"]["scheme"] = "http"
default["nova"]["services"]["ec2-public"]["network"] = "public"
default["nova"]["services"]["ec2-public"]["port"] = 8773
default["nova"]["services"]["ec2-public"]["path"] = "/services/Cloud"

default["nova"]["services"]["xvpvnc"]["scheme"] = "http"
default["nova"]["services"]["xvpvnc"]["network"] = "nova"
default["nova"]["services"]["xvpvnc"]["port"] = 6081
default["nova"]["services"]["xvpvnc"]["path"] = "/console"

default["nova"]["services"]["novnc"]["scheme"] = "http"
default["nova"]["services"]["novnc"]["network"] = "nova"
default["nova"]["services"]["novnc"]["port"] = 6080
default["nova"]["services"]["novnc"]["path"] = "/vnc_auto.html"

default["nova"]["services"]["volume"]["scheme"] = "http"
default["nova"]["services"]["volume"]["network"] = "public"
default["nova"]["services"]["volume"]["port"] = 8776
default["nova"]["services"]["volume"]["path"] = "/v1/%(tenant_id)s"

# Logging stuff
default["nova"]["syslog"]["use"] = true
default["nova"]["syslog"]["facility"] = "LOG_LOCAL1"
default["nova"]["syslog"]["config_facility"] = "local1"

# can this be wedged into the "api" endpoint?
default["nova"]["compute"]["region"] = "RegionOne"

# TODO(shep): This should probably be ['nova']['network']['fixed']
default["nova"]["networks"] = [
        {
                "label" => "public",
                "ipv4_cidr" => "192.168.100.0/24",
                "num_networks" => "1",
                "network_size" => "255",
                "bridge" => "br100",
                "bridge_dev" => "eth2",
                "dns1" => "8.8.8.8",
                "dns2" => "8.8.4.4"
        },
        {
                "label" => "private",
                "ipv4_cidr" => "192.168.200.0/24",
                "num_networks" => "1",
                "network_size" => "255",
                "bridge" => "br200",
                "bridge_dev" => "eth3",
                "dns1" => "8.8.8.8",
                "dns2" => "8.8.4.4"
        }
]

default["nova"]["network"]["fixed_range"] = default["nova"]["networks"][0]["ipv4_cidr"]
default["nova"]["network"]["dmz_cidr"] = "10.128.0.0/24"
default["nova"]["network"]["network_manager"] = "nova.network.manager.FlatDHCPManager"

default["nova"]["scheduler"]["scheduler_driver"] = "nova.scheduler.simple.SimpleScheduler"
default["nova"]["scheduler"]["default_filters"] = ["AvailabilityZoneFilter",
                                                   "RamFilter",
                                                   "ComputeFilter",
                                                   "CoreFilter",
                                                   "SameHostFilter",
                                                   "DifferentHostFilter"]
default["nova"]["libvirt"]["virt_type"] = "kvm"
default["nova"]["libvirt"]["vncserver_listen"] = node["ipaddress"]
default["nova"]["libvirt"]["vncserver_proxyclient_address"] = node["ipaddress"]
default["nova"]["libvirt"]["auth_tcp"] = "none"
default["nova"]["config"]["availability_zone"] = "nova"
default["nova"]["config"]["default_schedule_zone"] = "nova"
default["nova"]["config"]["force_raw_images"] = false

case platform
when "fedora", "redhat"
  default["nova"]["platform"] = {
    "api_ec2_packages" => ["openstack-nova"],
    "api_ec2_service" => "openstack-nova-api",
    "api_os_compute_packages" => ["openstack-nova"],
    "api_os_compute_service" => "openstack-nova-api",
    "api_os_volume_packages" => ["openstack-nova"],
    "api_os_volume_service" => "openstack-nova-api",
    "nova_volume_packages" => ["openstack-nova"],
    "nova_volume_service" => "openstack-nova-volume",
    "nova_api_metadata_packages" => ["openstack-nova"],
    "nova_api_metadata_service" => "openstack-nova-api",
    "nova_compute_packages" => ["openstack-nova"], # seriously?
    "nova_compute_service" => "openstack-nova-compute",
    "nova_network_packages" => ["iptables", "openstack-nova"],
    "nova_network_service" => "openstack-nova-network",
    "nova_scheduler_packages" => ["openstack-nova"],
    "nova_scheduler_service" => "openstack-nova-scheduler",
    "nova_vncproxy_packages" => ["openstack-nova"],
    "nova_vncproxy_service" => "openstack-nova-vncproxy",
    "nova_vncproxy_consoleauth_packages" => ["openstack-nova"],
    "libvirt_packages" => ["libvirt"],
    "libvirt_service" => "libvirtd",
    "mysql_service" => "mysqld",
    "common_packages" => ["openstack-nova"],
    "iscsi_helper" => "ietadm",
    "package_overrides" => "",
  }
when "ubuntu"
  default["nova"]["platform"] = {
    "api_ec2_packages" => ["nova-api-ec2"],
    "api_ec2_service" => "nova-api-ec2",
    "api_os_compute_packages" => ["nova-api-os-compute"],
    "api_os_compute_service" => "nova-api-os-compute",
    "api_os_volume_packages" => ["nova-api-os-volume"],
    "api_os_volume_service" => "nova-api-os-volume",
    "nova_api_metadata_packages" => ["nova-api-metadata"],
    "nova_api_metadata_service" => "nova-api-metadata",
    "nova_volume_packages" => ["nova-volume"],
    "nova_volume_service" => "nova-volume",
    "nova_compute_packages" => ["nova-compute"],
    "nova_compute_service" => "nova-compute",
    "nova_network_packages" => ["iptables", "nova-network"],
    "nova_network_service" => "nova-network",
    "nova_scheduler_packages" => ["nova-scheduler"],
    "nova_scheduler_service" => "nova-scheduler",
    "nova_vncproxy_packages" => ["novnc"],
    "nova_vncproxy_service" => "novnc",
    "nova_vncproxy_consoleauth_packages" => ["nova-consoleauth"],
    "nova_vncproxy_consoleauth_service" => "nova-consoleauth",
    "libvirt_packages" => ["libvirt-bin"],
    "libvirt_service" => "libvirt-bin",
    "mysql_service" => "mysql",
    "common_packages" => ["nova-common"],
    "iscsi_helper" => "tgtadm",
    "package_overrides" => "-o Dpkg::Options::='--force-confold' -o Dpkg::Options::='--force-confdef'"
  }
end
