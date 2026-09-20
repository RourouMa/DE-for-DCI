Get[FileNameJoin[{DirectoryName[DirectoryName[$InputFileName]],"Kernel","ConformalIBP.wl"}]];
assert[test_,name_]:=If[TrueQ[test],Print["PASS ",name],Print["FAIL ",name];Quit[1]];
kin={SP[X1,X1]->2 x,SP[X3,X3]->2 x,SP[X2,X2]->2 y,SP[X4,X4]->2 y,
 SP[X1,X3]->1+x^2,SP[X2,X4]->1+y^2,SP[X1,X2]->0,SP[X1,X4]->0,SP[X2,X3]->0,SP[X3,X4]->0};
f=LadderFamily[2,kin,{x,y}];g=CanonicalIntegral[f,G@@Join[f["TopSector"],{1,1}]];
b1=BoundaryIntegral[1,{1,1,1,1,1}];b2=BoundaryIntegral[1,{2,0,2,0,1}];
eq={g-b1,b1-2 b2};
a=ReduceIntegrals[f,{g,b1},eq,"Solver"->"Exact"];
assert[AssociationQ[a] && a["ExactEquationResidualsZero"] && a["Idempotent"],"full residuals and source idempotence"];
assert[a["ReducedTargets"]==={2 b2,2 b2},"source pivot retained in target images"];
assert[Length[a["SameLoopRules"]]===1 && Length[a["BoundaryRules"]]===2,"separate same-loop and boundary exports"];
assert[a["RawMasters"]==={} && a["BoundarySources"]==={b2},"lower sources do not become same-loop masters"];
bad=ReduceIntegrals[f,{g},eq,"Solver"->Function[{equations,columns,queries},{g->b1}]];
assert[FailureQ[bad] && bad[[1]]==="UnverifiedReduction","omitted boundary constraint still fails exact verification"];
free=ReduceIntegrals[f,{g+b1},{},"Solver"->"Exact"];
assert[free["ReducedTargets"]==={g+b1} && MemberQ[free["ColumnOrder"],b1],"unconstrained target source retained"];
cover=BuildFiniteBasis[f,{g+b1}];
assert[AssociationQ[cover] && cover["Basis"]==={g} && cover["BoundaryRows"]==={b1},"finite basis uses only same-loop support"];
If[MemberQ[Join[$CommandLine,$ScriptCommandLine],"--finiteflow"],
 args=Take[If[Length[$ScriptCommandLine]>=3,$ScriptCommandLine,$CommandLine],-2];
 assert[InitializeFiniteFlow@@args,"load FiniteFlow"];
 b=ReduceIntegrals[f,{g,b1},eq,"Solver"->"FiniteFlow"];
 assert[AssociationQ[b] && b["ReducedTargets"]===a["ReducedTargets"] && b["ExactEquationResidualsZero"],"FiniteFlow retains source pivots like exact elimination"]];
assert[$MessageList==={},"no unexpected Wolfram messages"];
Quit[0];
