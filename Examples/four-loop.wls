(* Bounded first pass, NOT a claim of four-loop closure. Increase limits only after inspecting the audit. *)
root=DirectoryName[DirectoryName[$InputFileName]];
Get[FileNameJoin[{root,"Kernel","ConformalIBP.wl"}]];
Get[FileNameJoin[{root,"Examples","kinematics.wl"}]];
If[StringQ[Environment["FINITEFLOW_INSTALL"]] && StringQ[Environment["FINITEFLOW_MATHLINK"]],
 If[!TrueQ[InitializeFiniteFlow[Environment["FINITEFLOW_INSTALL"],Environment["FINITEFLOW_MATHLINK"]]],Quit[1]]];
family=LadderFamily[4,kinematics,{x,y}];
top=G@@Join[family["TopSector"],ConstantArray[1,4]];
Print["Propagators: ",FamilyPropagators[family]];Print["Top: ",top];
result=RunDE[family,top,"Workers"->4,"MaxRounds"->1,"MaxSystemExpansions"->1,
 Sequence@@Get[FileNameJoin[{root,"Examples","four-loop-count-policy.wl"}]],
 "OutputDirectory"->FileNameJoin[{root,"runs","four-loop"}]];
Print[KeyTake[result,{"Status","History","Closed"}]];
Quit[If[FailureQ[result] || FailureQ[Lookup[result,"Status",None]],1,0]];
