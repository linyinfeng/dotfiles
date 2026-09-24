{ self, inputs, ... }:
{
  lib = {
    self = self.lib;
    nur = inputs.linyinfeng.lib;
  };
}
