{ ... }:
{
  boot.extraModprobeConfig = ''
    options snd_seq_dummy ports=4
  '';
}
