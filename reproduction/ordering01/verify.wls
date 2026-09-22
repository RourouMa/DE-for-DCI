(* Run after replay.wls in a separate kernel. No precomputed derivative is input to replay. *)
hHome=DirectoryName[$InputFileName];hData=Environment["DCI_SNAPSHOT_DATA"];
If[!StringQ[hData] || hData==="",hData=FileNameJoin[{hHome,"data"}]];
hWork=Environment["DCI_REPLAY_OUT"];
If[!StringQ[hWork] || hWork==="",hWork=FileNameJoin[{hHome,"work","replay"}]];
hRead[root_,k_,file_]:=Get[FileNameJoin[{root,"round"<>ToString[k],file}]];
hChecks=Table[Module[{ref=hRead[FileNameJoin[{hData,"reference"}],k,"NextInput.wl"],
 actual=hRead[hWork,k,"NextInput.wl"],s=hRead[hWork,k,"Summary.wl"]},
 <|"Round"->k,"Count"->s["NextInputCount"],
 "CountMatches"->(s["NextInputCount"]==={4,12,26,66}[[k]]),
 "ExactBasisAndDefinitions"->(Lookup[actual,{"Basis","Definitions","InputExpanded"}]===
  Lookup[ref,{"Basis","Definitions","InputExpanded"}]),
 "ExactTargets"->(hRead[hWork,k,"derivatives/Targets.wl"]===hRead[FileNameJoin[{hData,"reference"}],k,"derivatives/Targets.wl"]),
 "ExactReducedDE"->(hRead[hWork,k,"ReducedDEG4.wl"]===hRead[FileNameJoin[{hData,"reference"}],k,"ReducedDEG4.wl"]),
 "AlgebraicChecks"->And@@Values[hRead[hWork,k,"Checks.wl"]],
 "PoleAdmission"->TrueQ[hRead[hWork,k,"OutputAdmission.wl"]["Accepted"]],
 "BareDivergentZero"->(s["BareDivergent"]===0)|>],{k,4}];
hPassed=And@@Flatten[Values[KeyDrop[#,{"Round","Count"}]]& /@ hChecks];
Print[hChecks//InputForm];Put[<|"Passed"->hPassed,"Checks"->hChecks,"WolframVersion"->$Version|>,
 FileNameJoin[{hWork,"Verification.wl"}]];
Quit[If[TrueQ[hPassed],0,1]];
