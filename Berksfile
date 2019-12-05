source 'https://supermarket.chef.io'

%w(client -common -image -identity -network).each do |cookbook|
  if Dir.exist?("../cookbook-openstack#{cookbook}")
    cookbook "openstack#{cookbook}", path: "../cookbook-openstack#{cookbook}"
  else
    cookbook "openstack#{cookbook}", git: "https://opendev.org/openstack/cookbook-openstack#{cookbook}"
  end
end

metadata
