if builtins ? getFlake
then builtins.getFlake (toString ./.)
else (import ./lib/compat).defaultNix
