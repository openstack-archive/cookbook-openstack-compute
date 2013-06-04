require_relative "spec_helper"

describe "openstack-compute::ceilometer-db" do
  it "creates database and user" do
    ::Chef::Recipe.any_instance.should_receive(:db_create_with_user).
      with "metering", "ceilometer", "test-pass"

    converge
  end

  def converge
    ::Chef::Recipe.any_instance.stub(:db_password).with("ceilometer").
      and_return "test-pass"

    ::ChefSpec::ChefRunner.new(::UBUNTU_OPTS).converge "openstack-compute::ceilometer-db"
  end
end
