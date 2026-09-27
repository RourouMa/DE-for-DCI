root=DirectoryName[DirectoryName[$InputFileName]];Get[FileNameJoin[{root,"Kernel","ConformalIBP.wl"}]];Get[FileNameJoin[{root,"Examples","kinematics.wl"}]];
assert[q_,name_]:=If[TrueQ[q],Print["PASS ",name],Print["FAIL ",name];Quit[1]];
f=LadderFamily[1,kinematics,{x,y}];g=G[1,1,1,1,1];h=G[2,1,1,0,1];
inputs={g,(1+x)^6(g+h)/(1-y)^3,(x-y)g+(x+y)h,x g/(1+x)+g/(1+x),0};
fast=DifferentiateIntegrals[f,inputs];
legacy=Block[{ConformalIBP`Private`canonicalLinear,ConformalIBP`Private`coeff},
 ConformalIBP`Private`canonicalLinear[e_]:=ConformalIBP`Private`canonicalLinearExpanded[e];
 ConformalIBP`Private`coeff[rows_,vars_]:=Table[With[{expanded=Expand[r]},Together[Coefficient[expanded,#]]& /@ vars],{r,rows}];
 DifferentiateIntegrals[f,inputs]];
assert[AssociationQ[fast]&&AssociationQ[legacy],"both native derivative implementations accept the same valid input"];
assert[AllTrue[Flatten[Values[fast["Rows"]]-Values[legacy["Rows"]]],Together[#]===0&],"compact native derivatives equal legacy derivatives as exact rational linear expressions"];
assert[fast["Targets"]===legacy["Targets"],"native derivative target support is unchanged"];
primitive=DifferentiateIntegrals[f,{g}];
weighted=DifferentiateIntegrals[f,{(1+x)^6 g/(1-y)^3}];
assert[And@@Table[Together[First[weighted["Rows"][z]]-D[(1+x)^6/(1-y)^3,z]g-(1+x)^6 First[primitive["Rows"][z]]/(1-y)^3]===0,{z,{x,y}}],"all kinematic coefficient derivatives remain present"];
assert[$MessageList==={},"no unexpected messages"];Quit[0];
