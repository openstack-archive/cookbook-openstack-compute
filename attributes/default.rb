default["nova"]["db"]["name"] = "nova"
default["nova"]["db"]["username"] = "nova"
default["nova"]["db"]["password"] = "nova"

default["nova"]["service_tenant_name"] = "service"
default["nova"]["service_user"] = "nova"
default["nova"]["service_pass"] = "zCSupi4M"
default["nova"]["service_role"] = "admin"

default["nova"]["compute"]["api"]["protocol"] = "http"
default["nova"]["compute"]["api"]["port"] = "8774"
default["nova"]["compute"]["api"]["version"] = "v2"

default["nova"]["compute"]["region"] = "RegionOne"
default["nova"]["compute"]["adminURL"] = "#{node['nova']['compute']['api']['protocol']}://#{node['ipaddress']}:#{node['nova']['compute']['api']['port']}/#{node['nova']['compute']['api']['version']}/%(tenant_id)s"
default["nova"]["compute"]["internalURL"] = node["nova"]["compute"]["adminURL"]
default["nova"]["compute"]["publicURL"] = node["nova"]["compute"]["adminURL"]

default["nova"]["ec2"]["api"]["protocol"] = "http"
default["nova"]["ec2"]["api"]["port"] = "8773"
default["nova"]["ec2"]["api"]["admin_path"] = "services/Admin"
default["nova"]["ec2"]["api"]["cloud_path"] = "services/Cloud"

default["nova"]["ec2"]["adminURL"] = "#{node["nova"]["ec2"]["api"]["protocol"]}://#{node["ipaddress"]}:#{node["nova"]["ec2"]["api"]["port"]}/#{node["nova"]["ec2"]["api"]["admin_path"]}"
default["nova"]["ec2"]["publicURL"] = "#{node["nova"]["ec2"]["api"]["protocol"]}://#{node["ipaddress"]}:#{node["nova"]["ec2"]["api"]["port"]}/#{node["nova"]["ec2"]["api"]["cloud_path"]}"
default["nova"]["ec2"]["internalURL"] = node["nova"]["ec2"]["publicURL"]

default["nova"]["xvpvnc"]["proxy_bind_host"] = "0.0.0.0"
default["nova"]["xvpvnc"]["proxy_bind_port"] = "6081"
default["nova"]["xvpvnc"]["ip_address"] = node["ipaddress"]
default["nova"]["xvpvnc"]["proxy_base_url"] = "http://#{node['nova']['xvpvnc']['ip_address']}:#{node['nova']['xvpvnc']['proxy_bind_port']}/console"

default["nova"]["novnc"]["proxy_bind_port"] = "6080"
default["nova"]["novnc"]["proxy_base_url"] = "http://#{node['nova']['xvpvnc']['ip_address']}:#{node['nova']['novnc']['proxy_bind_port']}/vnc_auto.html"

default["nova"]["volume"]["api_port"] = 8776
default["nova"]["volume"]["ipaddress"] = node["ipaddress"]
default["nova"]["volume"]["adminURL"] = "http://#{node["nova"]["volume"]["ipaddress"]}:#{default["nova"]["volume"]["api_port"]}/v1"
default["nova"]["volume"]["internalURL"] = default["nova"]["volume"]["adminURL"]
default["nova"]["volume"]["publicURL"] = default["nova"]["volume"]["adminURL"]

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

default["nova"]["libvirt"]["virt_type"] = "kvm"
default["nova"]["libvirt"]["vncserver_listen"] = node["ipaddress"]
default["nova"]["libvirt"]["vncserver_proxyclient_address"] = node["ipaddress"]
default["nova"]["libvirt"]["auth_tcp"] = "none"
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
