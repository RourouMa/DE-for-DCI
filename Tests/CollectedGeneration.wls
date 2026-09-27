root=DirectoryName[DirectoryName[$InputFileName]];Get[FileNameJoin[{root,"Kernel","ConformalIBP.wl"}]];Get[FileNameJoin[{root,"Examples","kinematics.wl"}]];
assert[q_,name_]:=If[TrueQ[q],Print["PASS ",name],Print["FAIL ",name];Quit[1]];
Begin["ConformalIBP`Private`"];
referencePlannedGenerator[f_,targets_,options_,plan_]:=Module[{done=Association[(#->True)& /@ options["CompletedApplications"]],
 equations={},attempted={},rejected={},r,key,ops=plan["Operators"],syms,raw,newSymmetry,images},
 Do[Do[key={Hash[ops[[b["OperatorIndex"]]],"SHA256"],seed};If[KeyExistsQ[done,key],Continue[]];
  r=IBPRelation[f,ops[[b["OperatorIndex"]]],seed];AppendTo[attempted,key];AssociateTo[done,key->True];
  If[FailureQ[r],AppendTo[rejected,<|"Application"->key,"Failure"->r|>],If[!zero[r],AppendTo[equations,r]]],
  {seed,b["Seeds"]}],{b,plan["Batches"]}];
 Do[If[options["SeedDomain"]==="Original" && !originalDomainExpressionQ[f,seed],Continue[]];
  If[!FiniteIntegralQ[f,seed],Continue[]];
  Do[If[ops[[k]]["Degree"]=!=ConstantArray[0,f["LoopCount"]],Continue[]];
   key={Hash[ops[[k]],"SHA256"],seed};If[KeyExistsQ[done,key] || MemberQ[attempted,key],Continue[]];
   r=IBPRelation[f,ops[[k]],seed];AppendTo[attempted,key];AssociateTo[done,key->True];
   If[FailureQ[r],AppendTo[rejected,<|"Application"->key,"Failure"->r|>],If[!zero[r],AppendTo[equations,r]]],{k,Length[ops]}],
  {seed,options["FiniteSeeds"]}];
 raw=Union[support[targets],support[equations]];
 newSymmetry=Complement[raw,options["CompletedSymmetryInputs"]];
 images=CanonicalIntegral[f,#]& /@ newSymmetry;
 If[AnyTrue[images,FailureQ],Return[First[Select[images,FailureQ]]]];
 syms=newSymmetry-images;
 equations=DeleteCases[DeleteDuplicates[canonicalLinear /@ Join[equations,syms]],0];
 <|"Equations"->equations,"Applications"->attempted,"RejectedApplications"->rejected,
  "DegreeCoverageGaps"->plan["EmptyDegrees"],"SymmetryInputs"->raw,
  "NewSymmetryInputs"->newSymmetry,"AllGeneratedSupportCanonicalized"->True,"SeedGeometry"->plan["Geometry"],"SeedPolicy"->KeyTake[plan,{"SeedDomain","SeedCenters","BlockExpansion","InverseOperatorPolicy","UnmappedCenters"}],
  "SeedingDeduplication"->Lookup[plan,"SeedingDeduplication",<||>],"SeedPlanning"->Lookup[plan,"SeedPlanning",<||>],
  "AllActualSeedsInsideOriginalDomain"->And@@(originalDomainExpressionQ[f,Last[#]]& /@ attempted)|>];

End[];
f=LadderFamily[2,kinematics,{x,y}];top=G@@Join[f["TopSector"],{1,1}];
o=Join[Association[Options[GenerateSystem]],<|"SeedGeometry"->"InverseTargets","SeedDomain"->"Extended","SeedCenters"->"AllOriginalImages","FiniteSeeds"->{top,top}|>];
plan=GenerateSeeds[f,{top},Automatic,Sequence@@FilterRules[Normal[o],Options[GenerateSeeds]]];
plan["Batches"]=Join[(Join[#,<|"Seeds"->Take[#["Seeds"],UpTo[2]]|>]& /@ plan["Batches"]),Take[plan["Batches"],UpTo[1]]];
first=SelectFirst[plan["Batches"],#["Seeds"]=!={}&];o["CompletedApplications"]={{Hash[plan["Operators"][[first["OperatorIndex"]]],"SHA256"],First[first["Seeds"]]}};
a=ConformalIBP`Private`referencePlannedGenerator[f,{top},o,plan];b=ConformalIBP`Private`generatePlannedSystem[f,{top},o,plan];
assert[AssociationQ[a]&&a===b,"collector preserves exact equations, attempted/rejected applications, symmetry and metadata"];
assert[DuplicateFreeQ[b["Applications"]],"completed and overlapping planned applications are not repeated"];
assert[$MessageList==={},"no unexpected messages"];Quit[0];
