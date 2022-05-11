overlay:

final: prev:

if prev == null || (prev.isFakePkgs or false)
then { }
else overlay final prev
