{ ... }:
{
  specialisation = {
    v4First = {
      inheritParentConfig = true;
      configuration = {
        # man gai.conf
        # modified from the default gai.conf
        environment.etc."gai.conf".text = ''
          label  ::1/128       0
          label  ::/0          1
          label  2002::/16     2
          label ::/96          3
          label ::ffff:0:0/96  4
          precedence  ::1/128       50
          precedence  ::/0          40
          precedence  2002::/16     30
          precedence ::/96          20
          precedence ::ffff:0:0/96  100 # increase the precedence of ipv4 addresses
        '';
      };
    };
  };
}
