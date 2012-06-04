########################################################################
# Toggles - These can be overridden at the environment level
default["enable_monit"] = true  # OS provides packages
default["enable_collectd"] = false  # OS does not provide packages
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

# can this be wedged into the "api" endpoint?
default["nova"]["compute"]["region"] = "RegionOne"

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

default["nova"]["network"]["fixed_range"] = "192.168.100.0/24"
default["nova"]["network"]["dmz_cidr"] = "10.128.0.0/24"

default["nova"]["libvirt"]["virt_type"] = "kvm"
default["nova"]["libvirt"]["vncserver_listen"] = node["ipaddress"]
default["nova"]["libvirt"]["vncserver_proxyclient_address"] = node["ipaddress"]
default["nova"]["libvirt"]["auth_tcp"] = "none"
default["nova"]["config"]["availability_zone"] = "nova"

# FIXME: OMG!
default["nova"]["libvirt"]["ssh"]["private_key"] = "-----BEGIN DSA PRIVATE KEY-----
MIIBvAIBAAKBgQDUIz3rg0afavOwNeTJL/112U/l4B08kzZVx+QcflxllpW4sn/f
c+j+BeQ/sm2oW67vY9O/1GbN3FIN7Um3p0F9ycpfXpEiwk4UYneJtXFNhlu9rSrK
hWsEWENoKrCFhZ4Zuu8ads0DCMkU/ErumXMvJZQpSe+8CfguYSMbXvkYhQIVAPzY
syPKqOa3scshLqwPulZF64nZAoGABY60uqcFSJ8agPY2YZmLTsQ/OrVbUsnwT+RE
eXjqaofUvdlK43kWGw8I1v9Brh+32mFcYu2L0izv3ZvH9wd2OEiZnHxtZEojALBd
KMFRbC8PLC2Imz3yvNwEo+ZkgSo5LzP9nScyO/JDjbyOJAPEsCtKRxmth4XBcuY5
lPAtTlECgYEAtFtXDovPhgvLGhFrRZjBzp3HREWW1tihsWZA4qIFib+Rd+/s3lWG
CYiYhwoK8RM+z0TNXjBIWXpHwAqX5kFhg/xPySxWS58GePmPOXDbFEYq5FRWTx47
sQqRmVHmlZZ9AhsRfs65g4LlgJyBlWPeZ0xsfShYHKLKg5RrOGn90egCFQCcok5v
1TpUNWQC3NPFkwWHkp1zrg==
-----END DSA PRIVATE KEY-----"
default["nova"]["libvirt"]["ssh"]["public_key"] = "ssh-dss AAAAB3NzaC1kc3MAAACBANQjPeuDRp9q87A15Mkv/XXZT+XgHTyTNlXH5Bx+XGWWlbiyf99z6P4F5D+ybahbru9j07/UZs3cUg3tSbenQX3Jyl9ekSLCThRid4m1cU2GW72tKsqFawRYQ2gqsIWFnhm67xp2zQMIyRT8Su6Zcy8llClJ77wJ+C5hIxte+RiFAAAAFQD82LMjyqjmt7HLIS6sD7pWReuJ2QAAAIAFjrS6pwVInxqA9jZhmYtOxD86tVtSyfBP5ER5eOpqh9S92UrjeRYbDwjW/0GuH7faYVxi7YvSLO/dm8f3B3Y4SJmcfG1kSiMAsF0owVFsLw8sLYibPfK83ASj5mSBKjkvM/2dJzI78kONvI4kA8SwK0pHGa2HhcFy5jmU8C1OUQAAAIEAtFtXDovPhgvLGhFrRZjBzp3HREWW1tihsWZA4qIFib+Rd+/s3lWGCYiYhwoK8RM+z0TNXjBIWXpHwAqX5kFhg/xPySxWS58GePmPOXDbFEYq5FRWTx47sQqRmVHmlZZ9AhsRfs65g4LlgJyBlWPeZ0xsfShYHKLKg5RrOGn90eg= root@example.com"

case platform
when "fedora"
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
    "nova_network_packages" => ["openstack-nova"],
    "nova_network_service" => "openstack-nova-network",
    "nova_scheduler_packages" => ["openstack-nova"],
    "nova_scheduler_service" => "openstack-nova-scheduler",
    "nova_vncproxy_packages" => ["openstack-nova"],
    "nova_vncproxy_service" => "openstack-nova-vncproxy",
    "nova_vncproxy_consoleauth_packages" => ["openstack-nova"],
    "libvirt_packages" => ["libvirt"],
    "libvirt_service" => "libvirtd",
    "common_packages" => ["openstack-nova"],
    "iscsi_helper" => "ietadm",
    "package_overrides" => "",
    "monit_commands" => {
      "mysqld" => {
        "start" => "/usr/sbin/service mysqld start",
        "stop" => "/usr/sbin/service mysqld stop"
      },
      "nova-compute" => {
        "start" => "/usr/sbin/service openstack-nova-compute start",
        "stop" => "/usr/sbin/service openstack-nova-compute stop"
      },
      "nova-network" => {
        "start" => "/usr/sbin/service openstack-nova-network start",
        "stop" => "/usr/sbin/service openstack-nova-network stop"
      },
      "nova-scheduler" => {
        "start" => "/usr/sbin/service openstack-nova-scheduler start",
        "stop" => "/usr/sbin/service openstack-nova-scheduler stop"
      },
      "nova-volume" => {
        "start" => "/usr/sbin/service openstack-nova-volume start",
        "stop" => "/usr/sbin/service openstack-nova-volume stop"
      },
      "nova-api-os-compute" => {
        "start" => "/usr/sbin/service openstack-nova-api-os-compute start",
        "stop" => "/usr/sbin/service openstack-nova-api-os-compute stop"
      },
      "nova-api-os-volume" => {
        "start" => "/usr/sbin/service openstack-nova-api-os-volume start",
        "stop" => "/usr/sbin/service openstack-nova-api-os-volume stop"
      },
      "nova-api-ec2" => {
        "start" => "/usr/sbin/service openstack-nova-api-ec2 start",
        "stop" => "/usr/sbin/service openstack-nova-api-ec2 stop"
      },
      "nova-api-metadata" => {
        "start" => "/usr/sbin/service openstack-nova-api-metadata start",
        "stop" => "/usr/sbin/service openstack-nova-api-metadata stop"
      },
      "libvirt-bin" => {
        "start" => "/usr/sbin/service libvirt-bin start",
        "stop" => "/usr/sbin/service libvirt-bin stop"
      }
    }
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
    "nova_network_packages" => ["nova-network"],
    "nova_network_service" => "nova-network",
    "nova_scheduler_packages" => ["nova-scheduler"],
    "nova_scheduler_service" => "nova-scheduler",
    "nova_vncproxy_packages" => ["nova-vncproxy"],
    "nova_vncproxy_service" => "nova-vncproxy",
    "nova_vncproxy_consoleauth_packages" => ["nova-consoleauth"],
    "nova_vncproxy_consoleauth_service" => "nova-consoleauth",
    "libvirt_packages" => ["libvirt-bin"],
    "libvirt_service" => "libvirt-bin",
    "common_packages" => ["nova-common"],
    "iscsi_helper" => "tgtadm",
    "package_overrides" => "-o Dpkg::Options::='--force-confold' -o Dpkg::Options::='--force-confdef'",
    "monit_commands" => {
      "mysqld" => {
        "start" => "/usr/sbin/service mysql start",
        "stop" => "/usr/sbin/service mysql stop"
      },
      "nova-compute" => {
        "start" => "/usr/sbin/service nova-compute start",
        "stop" => "/usr/sbin/service nova-compute stop"
      },
      "nova-network" => {
        "start" => "/usr/sbin/service nova-network start",
        "stop" => "/usr/sbin/service nova-network stop"
      },
      "nova-scheduler" => {
        "start" => "/usr/sbin/service nova-scheduler start",
        "stop" => "/usr/sbin/service nova-scheduler stop"
      },
      "nova-volume" => {
        "start" => "/usr/sbin/service nova-volume start",
        "stop" => "/usr/sbin/service nova-volume stop"
      },
      "nova-api-os-compute" => {
        "start" => "/usr/sbin/service nova-api-os-compute start",
        "stop" => "/usr/sbin/service nova-api-os-compute stop"
      },
      "nova-api-os-volume" => {
        "start" => "/usr/sbin/service nova-api-os-volume start",
        "stop" => "/usr/sbin/service nova-api-os-volume stop"
      },
      "nova-api-ec2" => {
        "start" => "/usr/sbin/service nova-api-ec2 start",
        "stop" => "/usr/sbin/service nova-api-ec2 stop"
      },
      "nova-api-metadata" => {
        "start" => "/usr/sbin/service nova-api-metadata start",
        "stop" => "/usr/sbin/service nova-api-metadata stop"
      },
      "nova-consoleauth" => {
        "start" => "/usr/sbin/service nova-consoleauth start",
        "stop" => "/usr/sbin/service nova-consoleauth stop"
      },
      "libvirt-bin" => {
        "start" => "/usr/sbin/service libvirt-bin start",
        "stop" => "/usr/sbin/service libvirt-bin stop"
      }
    }

  }
end
