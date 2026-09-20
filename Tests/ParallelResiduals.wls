root=DirectoryName[DirectoryName[$InputFileName]];Get[FileNameJoin[{root,"Kernel","ConformalIBP.wl"}]];
Get[FileNameJoin[{root,"Examples","kinematics.wl"}]];
assert[t_,name_]:=If[TrueQ[t],Print["PASS ",name],Print["FAIL ",name];Quit[1]];
Needs["ProcessLink`"];streams=CreateDirectory[FileNameJoin[{$TemporaryDirectory,"parallel-residual-test-"<>CreateUUID[]}]];
Block[{ProcessLink`Private`$TempPrefix=FileNameJoin[{streams,"wl-stream-std"}]},
 f=LadderFamily[1,kinematics,{x,y}];top=G[1,1,1,1,1];sys=GenerateSystem[f,{top}];queries=DifferentiateIntegrals[f,{top}]["Targets"];
 serial=ReduceIntegrals[f,queries,sys["Equations"],"Solver"->"Exact","ReuseVerifiedReduction"->False];
 parallel=ReduceIntegrals[f,queries,sys["Equations"],"Solver"->"Exact","ReuseVerifiedReduction"->False,"VerificationWorkers"->3];
 assert[AssociationQ[parallel] && serial["Rules"]===parallel["Rules"] && serial["ReducedTargets"]===parallel["ReducedTargets"],"parallel numerical verification preserves rules and target normal forms"];
 assert[parallel["NumericalEquationResidualsZero"] && parallel["Idempotent"],"all two-point row checks and idempotence retained"];
 a=G[1];b=G[2];rows={a-x b,2 a-2 x b};
 good=ConformalIBP`Private`verifyEquationResiduals[rows,{a->x b},2,Automatic];
 assert[good==={0,0},"all valid rows covered"];
 bad=ConformalIBP`Private`verifyEquationResiduals[rows,{a->(x+1)b},2,Automatic];
 assert[bad==={1,1},"failed numerical residuals from every shard retained"];
 assert[FailureQ[ReduceIntegrals[f,queries,sys["Equations"],"VerificationWorkers"->0]],"invalid worker count rejected"];
 assert[$MessageList==={},"no unexpected Wolfram messages"]];Quit[0];
