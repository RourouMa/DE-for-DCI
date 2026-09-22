ibp4GeneratorVersionDirectory=DirectoryName[$InputFileName];
IBP4GeneratorFingerprint[]:=Hash[Table[{f,FileHash[
 FileNameJoin[{ibp4GeneratorVersionDirectory,f}],"SHA256"]},
 {f,{"IBP4loop.wl","IBP4FactorCache.wl","IBP4LaurentOperatorCache.wl",
  "IBP4ContactLaurentCache.wl","IBP4SeedDomain.wl"}}],"SHA256"];
