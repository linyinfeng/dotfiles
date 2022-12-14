{ ... }:

{
  boot.kernel.sysctl = {
    "net.ipv4.tcp_congestion_control" = "bbr";
  };
}
