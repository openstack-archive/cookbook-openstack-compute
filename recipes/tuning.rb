sysctl_multi "nova" do
  instructions "net.ipv4.ip_forward" => "1"
end
