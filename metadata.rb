name             'openstack-compute'
maintainer       'openstack-chef'
maintainer_email 'openstack-discuss@lists.openstack.org'
issues_url       'https://launchpad.net/openstack-chef'
source_url       'https://opendev.org/openstack/cookbook-openstack-compute'
license          'Apache-2.0'
description      'The OpenStack Compute service Nova.'
version          '18.0.0'

chef_version '>= 14.0'

recipe 'openstack-compute::api-metadata', 'Installs/Configures nova api metadata service'
recipe 'openstack-compute::api-os-compute', 'Installs/Configures nova api service'
recipe 'openstack-compute::compute', 'Installs/Configures nova compute service'
recipe 'openstack-compute::conductor', 'Installs/configures nova conductor service'
recipe 'openstack-compute::identity_registration', 'Identity registration'
recipe 'openstack-compute::libvirt', 'Installs/Configures libvirt'
recipe 'openstack-compute::nova-common', 'Common recipe for nova'
recipe 'openstack-compute::_nova_cell', 'Helper recipe for configuring nova cells'
recipe 'openstack-compute::nova-setup.rb', 'Nova setup recipe'
recipe 'openstack-compute::placement_api', 'Installs/Configures nova placement api'
recipe 'openstack-compute::scheduler', 'Installs/Configures nova scheduler service'
recipe 'openstack-compute::serialproxy', 'Installs/Configures nova serial proxy'
recipe 'openstack-compute::vncproxy', 'Installs/Configures nova vnc proxy'

%w(ubuntu redhat centos).each do |os|
  supports os
end

depends 'apache2', '~> 8.0'
depends 'openstack-common', '>= 18.0.0'
depends 'openstack-identity', '>= 18.0.0'
depends 'openstack-image', '>= 18.0.0'
depends 'openstack-network', '>= 18.0.0'
depends 'openstackclient'
