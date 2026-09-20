Get[FileNameJoin[{DirectoryName[DirectoryName[$InputFileName]],"Kernel","ConformalIBP.wl"}]];
kin={SP[X1,X1]->2 x,SP[X3,X3]->2 x,SP[X2,X2]->2 y,SP[X4,X4]->2 y,
 SP[X1,X3]->1+x^2,SP[X2,X4]->1+y^2,SP[X1,X2]->0,SP[X1,X4]->0,SP[X2,X3]->0,SP[X3,X4]->0};
f=LadderFamily[1,kin,{x,y}];ops=Flatten[ConstantArray[GenerateOperators[f],26],1];serial=GenerateSystem[f,{G[1,1,1,1,1]},"Operators"->ops];
ConformalIBP`Private`symmetryKnown[f["Hash"]]=<||>;
parallel=GenerateSystem[f,{G[1,1,1,1,1]},"Workers"->26,"Operators"->ops];
If[!AssociationQ[parallel],Print[InputForm[parallel]];Quit[1]];
ok=Union[serial["Equations"]]===parallel["Equations"] && Union[serial["Applications"]]===parallel["Applications"];
misses=0;cachedImages=Block[{ConformalIBP`Private`canonMemo},ConformalIBP`Private`canonMemo[args___]:=(misses++;$Failed);CanonicalIntegral[f,#]& /@ ConformalIBP`Private`support[parallel["Equations"]]];
ok=ok && misses===0 && FreeQ[cachedImages,$Failed];
Print[<|"ParentOrbitSearchesAfterWorkerMerge"->misses,"IndependentKernels"->parallel["IndependentKernels"],"SerialEqualsSharded"->ok|>];Quit[If[ok,0,1]];
