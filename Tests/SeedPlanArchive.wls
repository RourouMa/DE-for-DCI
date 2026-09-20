(* Compare seed applications with trusted worker archives from an unchanged
   package. The archive is executable Wolfram input and must be trusted. *)
root=DirectoryName[DirectoryName[$InputFileName]];
Get[FileNameJoin[{root,"Kernel","ConformalIBP.wl"}]];
args=If[Length[$ScriptCommandLine]>=3,$ScriptCommandLine,$CommandLine];
archive=Last[args];
inputs=Sort[FileNames["input*.wl",archive]];
outputs=Sort[FileNames["output*.wl",archive]];
If[inputs==={} || Length[inputs]=!=Length[outputs],Print["Archive is incomplete."];Quit[2]];
jobs=Get /@ inputs;results=Get /@ outputs;
If[!And@@(AssociationQ /@ results),Print["Invalid worker outputs."];Quit[1]];
job=First[jobs];opts=Association[job["Options"]];
If[Lookup[opts,"FiniteSeeds",{}]=!={},Print["This audit expects monomial seed jobs."];Quit[2]];
operators=Flatten[Lookup[Association[# ["Options"]]& /@ jobs,"Operators"],1];
timing=AbsoluteTiming[plan=GenerateSeeds[job["Family"],job["Targets"],operators,Sequence@@Normal[Join[<|"SeedDomain"->"Extended","SeedCenters"->"Raw","BlockExpansion"->"Cartesian"|>,KeyTake[opts,{"SeedDomain","SeedCenters","BlockExpansion"}]]]];];
If[!AssociationQ[plan],Print[plan];Quit[1]];
applications=Union[Flatten[Table[
 Table[{Hash[operators[[batch["OperatorIndex"]]],"SHA256"],seed},{seed,batch["Seeds"]}],
 {batch,plan["Batches"]}],1]];
applications=Complement[applications,opts["CompletedApplications"]];
expected=Union[Flatten[Lookup[results,"Applications"],1]];
summary=<|"Archive"->archive,"Centers"->Length[job["Targets"]],"Operators"->Length[operators],
 "SeedPlanSeconds"->First[timing],"ExpectedApplications"->Length[expected],
 "ActualApplications"->Length[applications],"ApplicationsExactlyEqual"->(applications===expected),
 "MissingApplications"->Length[Complement[expected,applications]],
 "ExtraApplications"->Length[Complement[applications,expected]]|>;
Print[summary];Quit[If[applications===expected,0,1]];
