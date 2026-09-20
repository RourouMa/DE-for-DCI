root=DirectoryName[DirectoryName[$InputFileName]];Get[FileNameJoin[{root,"Kernel","ConformalIBP.wl"}]];Get[FileNameJoin[{root,"Examples","kinematics.wl"}]];
assert[t_,name_]:=If[TrueQ[t],Print["PASS ",name],Print["FAIL ",name];Quit[1]];
f=LadderFamily[2,kinematics,{x,y}];a=G[2,0,0,0,0,2,0,0,2,1,1];b=G[1,1,0,0,1,1,0,0,2,1,1];c=G[3,-1,0,0,-1,3,0,0,2,1,1];candidate=a+b-2 c;
source=BoundaryIntegral[1,{1,1,1,1,1}];
r=BuildFiniteBasis[f,{x candidate+source,y candidate}];
assert[AssociationQ[r] && r["ExactCoverage"] && Length[r["Combinations"]]===1 && Length[ConformalIBP`Private`support[First[r["Combinations"]]]]===3,"three-term zero-sum combination with source passes"];
bad=BuildFiniteBasis[f,{x(a+b-c)}];assert[FailureQ[bad] && bad[[1]]==="NoConstantZeroSumCover","nonzero sum fails before matrix extraction"];
empty=BuildFiniteBasis[f,{source}];assert[AssociationQ[empty] && empty["Basis"]==={} && empty["BoundaryRows"]==={source},"source-only row preserved"];
assert[$MessageList==={},"no unexpected messages"];Quit[0];
