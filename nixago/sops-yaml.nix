{lib}: let
  main = "7D2F4C6B9A8300CCDDB641FDDF14B55A7A29C30F";
  yubikeys = {
    # TODO https://github.com/mozilla/sops/issues/1103
    # yubikey5 = "age1yubikey1qda6pkn5cf75zrx6kx4wdx287dlege8eucuhnr9zjl94dzsg56afwtma6nz";
  };
  yubikeyKeys = lib.attrValues yubikeys;
  github = "age143hpp7hqp4708z2dy868llsj8u9lc2jyq59ahnzusjvwg5g2u3cs3jaltg";
  hosts = {
    framework = {
      key = "age1qrrwcee244ak7ax9xwuxdttzsan24g655lpmvry3275j6v4n2pesjwyawu";
      owned = true;
    };
    xps8930 = {
      key = "age1ynhrpsfdwxm3ryzn6uyvqng5hca2em983qm6d8jkkhyq6u0w8qpq3gxxh0";
      owned = true;
    };
    enchilada = {
      key = "age14v83ttlaedgz4nd0tpffskp9eq398mprt9lsysjhyu7t8zafpyfq654tqt";
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
    hil0 = {
      key = "age1q4f93vlxr4k5a9tnu5r8p7q3ks597fnu7kyc42kp0qsg6y0zxekqpmpj7g";
      owned = true;
    };
    fsn0 = {
      key = "age1q8rds85ppw8uas9jk4dl4ynfvwm9qp92m0mry9aqse7zjvh5fpms5c98at";
      owned = true;
    };
    mia0 = {
      key = "age1knaw8w3lmmnwgncn65fegan62jkkpzg4hgqmpvaagqk8x26x5qlqs42efv";
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
  };
  ownedHostKeys = lib.mapAttrsToList (_: cfg: cfg.key) (lib.filterAttrs (_: cfg: cfg.owned) hosts);
  allHostKeys = lib.mapAttrsToList (_: cfg: cfg.key) hosts;
  vmTest = "age17cg7mctcy03vt7wckfezc0xv2ntanhqx48uma9x2cltxatg2dstqx45xhu";

  mkHostCreationRule = host: key: {
    path_regex = "^secrets/(terraform/)?hosts/${host}(\.plain)?\.yaml$";
    key_groups = [
      {
        pgp = [main];
        age = [github key];
      }
    ];
  };
in {
  creation_rules =
    [
      {
        path_regex = "^secrets/terraform-inputs\.yaml$";
        key_groups = [
          {
            pgp = [main];
            age = yubikeyKeys ++ [github];
          }
        ];
      }
      {
        path_regex = "^secrets/hosts/mtl0-terraform\.yaml$";
        key_groups = [
          {
            pgp = [main];
            age = yubikeyKeys ++ [hosts.mtl0.key github];
          }
        ];
      }
      {
        path_regex = "^secrets/terraform-outputs\.yaml$";
        key_groups = [
          {
            pgp = [main];
            age = yubikeyKeys ++ [github];
          }
        ];
      }
      {
        path_regex = "terraform.(tfstate|plan)$";
        key_groups = [
          {
            pgp = [main];
            age = yubikeyKeys ++ [github];
          }
        ];
      }
      {
        path_regex = "^secrets/(terraform/)?common\.yaml$";
        key_groups = [
          {
            pgp = [main];
            age = yubikeyKeys ++ ownedHostKeys ++ [github];
          }
        ];
      }
      {
        path_regex = "^secrets/(terraform/)?infrastructure\.yaml$";
        key_groups = [
          {
            pgp = [main];
            age = yubikeyKeys ++ allHostKeys ++ [github];
          }
        ];
      }
      {
        path_regex = "^/tmp/encrypt.*$";
        key_groups = [
          {
            pgp = [main];
            age = yubikeyKeys ++ [github];
          }
        ];
      }
      {
        path_regex = "^modules/sops/vm-test/test-secrets/.*\.yaml$";
        key_groups = [
          {
            pgp = [main];
            age = yubikeyKeys ++ [github vmTest];
          }
        ];
      }
    ]
    ++ lib.mapAttrsToList (host: cfg: mkHostCreationRule host cfg.key) hosts;
}
