(* Recompose raw rules from a saved full solve, without solving the matrix again. *)
hHome=DirectoryName[$InputFileName];hData=Environment["DCI_SNAPSHOT_DATA"];
If[!StringQ[hData] || hData==="",hData=FileNameJoin[{hHome,"data"}]];
hWork=Environment["DCI_SOLVE_OUT"];
If[!StringQ[hWork] || hWork==="",hWork=FileNameJoin[{hHome,"work","solve"}]];
Get[FileNameJoin[{hHome,"normal_form.wl"}]];
hSol=Get[FileNameJoin[{hWork,"CanonicalReductionRules.wl"}]];
hMap=Get[FileNameJoin[{hData,"matrix","QueryMap.wl"}]];
If[!ListQ[hSol] || !ListQ[hMap],Print["Missing solved canonical rules"];Quit[1]];
hRules=Thread[(First /@ hMap)->(SnapshotLinearNormal /@ ((Last /@ hMap)/.Dispatch[hSol]))];
hExpected=Get[FileNameJoin[{hData,"reduction","IBP4ReductionRules.txt"}]];
hSame=First /@ hRules===First /@ hExpected &&
 And@@(#===0& /@ (SnapshotLinearNormal /@ ((Last /@ hRules)-(Last /@ hExpected))));
If[!TrueQ[hSame],Print["Raw rules differ from frozen reference"];Quit[1]];
Put[hRules,FileNameJoin[{hWork,"IBP4ReductionRules.txt"}]];
Do[CopyFile[FileNameJoin[{hData,"reduction",hFile}],FileNameJoin[{hWork,hFile}],OverwriteTarget->True],
 {hFile,{"OrderingSummary.wl","Projection.wl"}}];
Put[<|"ExactRawRulesMatch"->hSame,"RuleCount"->Length[hRules],
 "CanonicalFileByteIdentical"->(FileHash[FileNameJoin[{hWork,"CanonicalReductionRules.wl"}],"SHA256"]===
 FileHash[FileNameJoin[{hData,"matrix","CanonicalReductionRules.wl"}],"SHA256"]),
 "CompactFileBytes"->FileByteCount[FileNameJoin[{hWork,"IBP4ReductionRules.txt"}]]|>,
 FileNameJoin[{hWork,"CompositionVerification.wl"}]];
Print[Get[FileNameJoin[{hWork,"CompositionVerification.wl"}]]//InputForm];Quit[];
