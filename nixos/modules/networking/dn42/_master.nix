{
  config,
  lib,
  ...
}: let
  cfg = config.networking.dn42;
  bgpCfg = cfg.bgp;
in
  # aggregate all routes to master4 amd master6
  lib.mkIf (cfg.enable) {
    services.bird2.config = lib.mkOrder 300 ''
      protocol pipe pipe_mesh_v4_to_master4 {
        table mesh_v4;
        peer table master4;
        export all;
        import none;
      }
      protocol pipe pipe_mesh_v6_to_master6 {
        table mesh_v6;
        peer table master6;
        export all;
        import none;
      }
      ${lib.optionalString bgpCfg.enable ''
        protocol pipe pipe_bgp_v4_to_master4 {
          table bgp_v4;
          peer table master4;
          export all;
          import none;
        }
        protocol pipe pipe_bgp_v6_to_master6 {
          table bgp_v6;
          peer table master6;
          export all;
          import none;
        }
      ''}
    '';
  }
