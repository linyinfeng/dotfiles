final: prev: {
  # Fix profiles/core in vm-test
  utillinux = final.util-linux;
  # Fix emacs overlay in vm-test
  emacsPackagesGen = final.emacsPackagesFor;
}
