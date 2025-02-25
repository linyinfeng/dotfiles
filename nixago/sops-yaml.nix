{ lib }:
let
  pgp = [
    "7D2F4C6B9A8300CCDDB641FDDF14B55A7A29C30F"
    "0x1D0FFC1902304AED!" # old subkey
    "0x670D90CAD2B210B3!" # new subkey
  ];
  yubikeys = {
    # TODO https://github.com/mozilla/sops/issues/1103
    # yubikey5 = "age1yubikey1qda6pkn5cf75zrx6kx4wdx287dlege8eucuhnr9zjl94dzsg56afwtma6nz";
  };
  yubikeyKeys = lib.attrValues yubikeys;
  github = "age143hpp7hqp4708z2dy868llsj8u9lc2jyq59ahnzusjvwg5g2u3cs3jaltg";
  hosts = {
    owl = {
      key = "age1qrrwcee244ak7ax9xwuxdttzsan24g655lpmvry3275j6v4n2pesjwyawu";
      owned = true;
    };
    xps8930 = {
      key = "age1ynhrpsfdwxm3ryzn6uyvqng5hca2em983qm6d8jkkhyq6u0w8qpq3gxxh0";
      owned = true;
    };
    enchilada = {
      key = "age1y6rknxt06p8pjzyn5s3g9ljq87k706675eurcyqxmqgnujka9sxs4922mj";
      owned = true;
    };
    nuc = {
      key = "age1pf99e6kfd52kugec6t27t9nkere8vn3guk5t04v7ldde4cnlwpwsm0n4gj";
      owned = true;
    };
    mtl0 = {
      key = "age1eele84f8nufp7g2j8cws8z2su0kp9ldgcvj8gmgldc326j7ykv9qzxcuaa";
      owned = true;
    };
    fsn0 = {
      key = "age1q8rds85ppw8uas9jk4dl4ynfvwm9qp92m0mry9aqse7zjvh5fpms5c98at";
      owned = true;
    };
    lax0 = {
      key = "age1xfgelz64gnpx28pfga9ntwe8869ra0ksde6vmkxczlfzfqrqr9us4mntmx";
      owned = true;
    };
    hkg0 = {
      key = "age1r0m4u6wpegaxxs6dlknkgwxd637p88wjvljladv9l7l7v60kgf2q7p3jcp";
      owned = true;
    };
    shg0 = {
      key = "age1wzm6xztn2m08qr74hg29nv2qlz8537apl4kcqakfyg3gc8l0mcgstrqjpf";
      owned = true;
    };
    # PLACEHOLDER new host
  };
  ownedHostKeys = lib.mapAttrsToList (_: cfg: cfg.key) (lib.filterAttrs (_: cfg: cfg.owned) hosts);
  allHostKeys = lib.mapAttrsToList (_: cfg: cfg.key) hosts;

  mkHostCreationRule = host: key: {
    path_regex = "secrets/(terraform/)?hosts/${host}(\.plain)?\.yaml$";
    key_groups = [
      {
        inherit pgp;
        age = [
          github
          key
        ];
      }
    ];
  };
in
{
  creation_rules = [
    {
      path_regex = "terraform-inputs\.yaml$";
      key_groups = [
        {
          inherit pgp;
          age = yubikeyKeys ++ [ github ];
        }
      ];
    }
    {
      path_regex = "terraform-outputs\.yaml$";
      key_groups = [
        {
          inherit pgp;
          age = yubikeyKeys ++ [ github ];
        }
      ];
    }
    {
      path_regex = "terraform.(tfstate|plan)$";
      key_groups = [
        {
          inherit pgp;
          age = yubikeyKeys ++ [ github ];
        }
      ];
    }
    {
      path_regex = "secrets/hosts/mtl0-terraform\.yaml$";
      key_groups = [
        {
          inherit pgp;
          age = yubikeyKeys ++ [
            hosts.mtl0.key
            github
          ];
        }
      ];
    }
    {
      path_regex = "secrets/(terraform/)?common\.yaml$";
      key_groups = [
        {
          inherit pgp;
          age = yubikeyKeys ++ ownedHostKeys ++ [ github ];
        }
      ];
    }
    {
      path_regex = "secrets/(terraform/)?infrastructure\.yaml$";
      key_groups = [
        {
          inherit pgp;
          age = yubikeyKeys ++ allHostKeys ++ [ github ];
        }
      ];
    }
    {
      path_regex = "^/tmp/encrypt.*$";
      key_groups = [
        {
          inherit pgp;
          age = yubikeyKeys ++ [ github ];
        }
      ];
    }
  ] ++ lib.mapAttrsToList (host: cfg: mkHostCreationRule host cfg.key) hosts;
}
