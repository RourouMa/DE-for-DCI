Get[FileNameJoin[{DirectoryName[DirectoryName[$InputFileName]],"Kernel","ConformalIBP.wl"}]];
assert[test_,name_]:=If[TrueQ[test],Print["PASS ",name],Print["FAIL ",name];Quit[1]];
kin={SP[X1,X1]->2 x,SP[X3,X3]->2 x,SP[X2,X2]->2 y,SP[X4,X4]->2 y,
 SP[X1,X3]->1+x^2,SP[X2,X4]->1+y^2,SP[X1,X2]->0,SP[X1,X4]->0,SP[X2,X3]->0,SP[X3,X4]->0};
f=LadderFamily[1,kin,{x,y}];g=G[1,1,1,1,1];
run=RunDE[f,g,"Solver"->"Exact","GenerationPolicy"->"OnDemand","MaxRounds"->6,"MaxSystemExpansions"->8,"ProgressFunction"->None];
assert[AssociationQ[run] && run["Closed"] && run["FlatnessVerified"],"demand-driven one-loop DE closes with exact flatness"];
assert[Length[run["Basis"]]===4 && Length[run["History"]]>=2,"finite cover feeds a subsequent derivative round"];
assert[run["LastReduction"]["NumericalEquationResidualsZero"] && run["LastReduction"]["Idempotent"],"full reduction verification retained"];
assert[run["CompletedApplications"]=!={},"missing targets trigger actual IBP generation"];
assert[And@@(FiniteIntegralQ[f,#]& /@ run["Basis"]),"final differentiated inputs remain certified finite"];
assert[FailureQ[RunDE[f,g,"GenerationPolicy"->"invalid"]],"invalid scheduling option rejected"];
assert[$MessageList==={},"no unexpected Wolfram messages"];
Quit[0];
