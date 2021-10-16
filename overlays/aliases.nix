final: prev: {
  __dontExport = true;

  # Fix emacs overlay in vm-test
  emacsPackagesGen = final.emacsPackagesFor;
}
