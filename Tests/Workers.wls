Get[FileNameJoin[{DirectoryName[DirectoryName[$InputFileName]],"Kernel","ConformalIBP.wl"}]];
kin={SP[X1,X1]->2 x,SP[X3,X3]->2 x,SP[X2,X2]->2 y,SP[X4,X4]->2 y,
 SP[X1,X3]->1+x^2,SP[X2,X4]->1+y^2,SP[X1,X2]->0,SP[X1,X4]->0,SP[X2,X3]->0,SP[X3,X4]->0};
f=LadderFamily[1,kin,{x,y}];serial=GenerateSystem[f,{G[1,1,1,1,1]}];
Needs["ProcessLink`"];
streams=CreateDirectory[FileNameJoin[{$TemporaryDirectory,"ibp-workers-test-"<>CreateUUID[]}]];
parallel=Block[{ProcessLink`Private`$TempPrefix=FileNameJoin[{streams,"wl-stream-std"}]},GenerateSystem[f,{G[1,1,1,1,1]},"Workers"->4]];
If[!AssociationQ[parallel],Print[InputForm[parallel]];Quit[1]];
ok=Union[serial["Equations"]]===parallel["Equations"] && Union[serial["Applications"]]===parallel["Applications"];
Print[<|"IndependentKernels"->parallel["IndependentKernels"],"SerialEqualsSharded"->ok|>];Quit[If[ok,0,1]];
