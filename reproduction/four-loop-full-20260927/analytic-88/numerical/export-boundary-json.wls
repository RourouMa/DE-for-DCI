$IterationLimit=Infinity;out=DirectoryName[$InputFileName];run=DirectoryName[out];f=FileNameJoin[{run,"global-boundary","CanonicalBoundary88.wl"}];a=Get[f];c=a["Constants"];
dec[z_]:=StringReplace[ToString[N[z,110],InputForm],{RegularExpression["`[0-9.]*"]->"","*^"->"e"}];
Export[FileNameJoin[{out,"CanonicalBoundary88.json"}],<|"Values"->(dec /@c),"SourceFile"->f,"SourceSHA256"->IntegerString[FileHash[f,"SHA256"],16,64],"PrecisionDigits"->110,"RaySlope"->4,"DirectNumericalEstimateUsed"->False|>,"RawJSON"];Print["values ",Length[c]];Quit[0];
