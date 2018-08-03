source 'https://supermarket.chef.io'

%w(common identity image network).each do |cookbook|
  if Dir.exist?("../cookbook-openstack-#{cookbook}")
    cookbook "openstack-#{cookbook}", path: "../cookbook-openstack-#{cookbook}"
  else
    cookbook "openstack-#{cookbook}", git: "https://git.openstack.org/openstack/cookbook-openstack-#{cookbook}"
  end
end

cookbook 'openstackclient',
  git: 'https://git.openstack.org/openstack/cookbook-openstackclient'

metadata
