$IterationLimit=Infinity;o=DirectoryName[$InputFileName];r=DirectoryName[DirectoryName[o]];
a=Get[FileNameJoin[{r,"dlog","Full88DLog.wl"}]];cf=Get[FileNameJoin[{o,"CanonicalFunctions88.wl"}]];
cf=cf/.{DCIAnalytic`ChenX[w_List]:>DCIAnalytic`ChenX[w,DCIAnalytic`x],DCIAnalytic`ChenY[w_List]:>DCIAnalytic`ChenY[w,DCIAnalytic`x,DCIAnalytic`y]};
mi=a["NewToNative"]/.{Global`x->DCIAnalytic`x,Global`y->DCIAnalytic`y};
Put[cf,FileNameJoin[{o,"CanonicalFunctionsExplicit88.wl"}]];Put[mi,FileNameJoin[{o,"CanonicalToNative88.wl"}]];
nf=Table[Total[Table[If[mi[[i,j]]===0,0,mi[[i,j]]cf[[j]]],{j,88}]],{i,88}];
Put[nf,FileNameJoin[{o,"NativeFunctions88.wl"}]];Put[nf[[1]],FileNameJoin[{o,"TopLadderFunctionExplicit.wl"}]];
Print[<|"NativeFunctions"->Length[nf],"CanonicalFunctions"->Length[cf],"AllBoundaryConstantsExplicit"->FreeQ[nf,HoldPattern[DCIAnalytic`B4]],"TopCoordinateExactlyOnlyJ1"->a["NewToNative"][[1,2;;88]]===ConstantArray[0,87],"NativeExpressionLeafCount"->LeafCount[nf]|>];Quit[];
