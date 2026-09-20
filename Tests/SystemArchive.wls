(* Trusted baseline worker archives only. Regenerate through the public API. *)
root=DirectoryName[DirectoryName[$InputFileName]];
Get[FileNameJoin[{root,"Kernel","ConformalIBP.wl"}]];
archive=Last[If[Length[$ScriptCommandLine]>=3,$ScriptCommandLine,$CommandLine]];
inputs=Sort[FileNames["input*.wl",archive]];outputs=Sort[FileNames["output*.wl",archive]];
If[inputs==={} || Length[inputs]=!=Length[outputs],Print["Archive is incomplete."];Quit[2]];
jobs=Get /@ inputs;baseline=Get /@ outputs;
job=First[jobs];job["Family"]=CreateFamily[Join[job["Family"],<|"IntegralOrdering"->Lookup[job["Family"],"IntegralOrdering","Legacy"]|>]];opts=Association[job["Options"]];
ops=Flatten[Lookup[Association[#["Options"]]& /@ jobs,"Operators"],1];
timing=AbsoluteTiming[generated=GenerateSystem[job["Family"],job["Targets"],
 "Operators"->ops,"Workers"->4,"CompletedApplications"->opts["CompletedApplications"],
 "FiniteSeeds"->opts["FiniteSeeds"],Sequence@@Normal[Join[<|"SeedDomain"->"Extended","SeedCenters"->"Raw","BlockExpansion"->"Cartesian"|>,KeyTake[opts,{"SeedDomain","SeedCenters","BlockExpansion"}]]]];];
If[!AssociationQ[generated],Print[generated];Quit[1]];
checks=<|"Equations"->(generated["Equations"]===Union[Flatten[Lookup[baseline,"Equations"]]]),
 "Applications"->(generated["Applications"]===Union[Flatten[Lookup[baseline,"Applications"],1]]),
 "RejectedApplications"->(Union[generated["RejectedApplications"]]===Union[Flatten[Lookup[baseline,"RejectedApplications"]]]),
 "SymmetryInputs"->(generated["SymmetryInputs"]===Union[Flatten[Lookup[baseline,"SymmetryInputs"]]])|>;
Print[<|"Archive"->archive,"Seconds"->First[timing],"EquationCount"->Length[generated["Equations"]],
 "ApplicationCount"->Length[generated["Applications"]],"ExactBaselineChecks"->checks|>];
Quit[If[And@@Values[checks],0,1]];
