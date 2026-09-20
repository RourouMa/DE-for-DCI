root=DirectoryName[DirectoryName[$InputFileName]];Get[FileNameJoin[{root,"Kernel","ConformalIBP.wl"}]];
Get[FileNameJoin[{root,"Examples","kinematics.wl"}]];
assert[t_,name_]:=If[TrueQ[t],Print["PASS ",name],Print["FAIL ",name];Quit[1]];
a=G[1];b=G[2];c=BoundaryIntegral[1,{1,1}];rows={(x+z)a-(x+z)b,(x^2+y)/(x-y) b+c,3 a-2 b};
assert[ConformalIBP`Private`coefficientParameters[rows]===Complement[Variables[rows],{a,b,c}],"coefficient inference equals automatic parameters"];
assert[ConformalIBP`Private`coefficientParameters[{(x+z)a-(x+z)b}]==={x,z},"parameters survive cancellation between different integral columns"];
assert[ConformalIBP`Private`coefficientParameters[{2 a,0}]==={} && ConformalIBP`Private`coefficientParameters[{}]==={},"numeric and empty pools"];
f=LadderFamily[2,kinematics,{x,y}];top=G@@Join[f["TopSector"],{1,1}];sys=GenerateSystem[f,{top}];
assert[ConformalIBP`Private`coefficientParameters[sys["Equations"]]===Complement[Variables[sys["Equations"]],Join[ConformalIBP`Private`support[sys["Equations"]],ConformalIBP`Private`sources[sys["Equations"]]]],"actual IBP pool parameter equality"];
If[StringQ[Environment["FINITEFLOW_ROOT"]],
 InitializeFiniteFlow[Environment["FINITEFLOW_ROOT"],FileNameJoin[{Environment["FINITEFLOW_ROOT"],"mathlink"}]];
 Needs["ProcessLink`"];streams=CreateDirectory[FileNameJoin[{$TemporaryDirectory,"coefficient-params-test-"<>CreateUUID[]}]];
 Block[{ProcessLink`Private`$TempPrefix=FileNameJoin[{streams,"wl-stream-std"}]},
 g=CanonicalIntegral[f,top];b1=BoundaryIntegral[1,{1,1,1,1,1}];b2=BoundaryIntegral[1,{2,0,2,0,1}];eq={g-z b1,b1-x b2};
 red=ReduceTargetIntegrals[f,{g},eq,"Solver"->"FiniteFlow","MinimumSelectionRows"->0];
 assert[AssociationQ[red] && red["ReducedTargets"]==={x z b2} && red["FullPoolTargetAgreement"],"extra coefficient parameter absent from DE-variable list reconstructed and verified"]]];
assert[$MessageList==={},"no unexpected Wolfram messages"];Quit[0];
