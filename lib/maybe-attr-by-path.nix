{ lib }:
name: from: attrPath:
if lib.hasAttrByPath attrPath from then { ${name} = lib.getAttrFromPath attrPath from; } else { }
