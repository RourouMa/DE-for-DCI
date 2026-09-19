Get[FileNameJoin[{DirectoryName[DirectoryName[$InputFileName]],"Kernel","ConformalIBP.wl"}]];
args=Take[If[Length[$ScriptCommandLine]>=3,$ScriptCommandLine,$CommandLine],-2];
If[!TrueQ[InitializeFiniteFlow@@args],Quit[1]];
kin={SP[X1,X1]->2 x,SP[X3,X3]->2 x,SP[X2,X2]->2 y,SP[X4,X4]->2 y,
 SP[X1,X3]->1+x^2,SP[X2,X4]->1+y^2,SP[X1,X2]->0,SP[X1,X4]->0,SP[X2,X3]->0,SP[X3,X4]->0};
f=LadderFamily[1,kin,{x,y}];targets=DifferentiateIntegrals[f,{G[1,1,1,1,1]}]["Targets"];
sys=GenerateSystem[f,targets];a=ReduceIntegrals[f,targets,sys["Equations"],"Solver"->"Exact"];
b=ReduceIntegrals[f,targets,sys["Equations"],"Solver"->"FiniteFlow"];
ok=AssociationQ[a] && AssociationQ[b] && And@@(TrueQ[Together[#]===0]& /@ (a["ReducedTargets"]-b["ReducedTargets"]));
Print[<|"ExactEqualsFiniteFlow"->ok|>];If[!ok,Print[b]];Quit[If[ok,0,1]];
