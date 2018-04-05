name             'openstack-compute'
maintainer       'openstack-chef'
maintainer_email 'openstack-dev@lists.openstack.org'
issues_url       'https://launchpad.net/openstack-chef' if respond_to?(:issues_url)
source_url       'https://github.com/openstack/cookbook-openstack-compute' if respond_to?(:source_url)
license          'Apache-2.0'
description      'The OpenStack Compute service Nova.'
version          '17.0.0'

chef_version '>= 12.5' if respond_to?(:chef_version)
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))

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

depends 'openstack-common', '>= 17.0.0'
depends 'openstack-identity', '>= 17.0.0'
depends 'openstack-image', '>= 17.0.0'
depends 'openstack-network', '>= 17.0.0'
depends 'openstackclient'
