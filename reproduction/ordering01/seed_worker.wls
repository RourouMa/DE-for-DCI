(* Replay saved degree-matched seeds with the frozen, contact-local generator. *)
swHome=DirectoryName[$InputFileName];swData=Environment["DCI_SNAPSHOT_DATA"];
If[!StringQ[swData] || swData==="",swData=FileNameJoin[{swHome,"data"}]];
swTag=Environment["DCI_SEED_TAG"];If[!StringQ[swTag] || swTag==="",swTag="targeted16"];
swID=Environment["IBP4_SHARD_ID"];
If[!MemberQ[{"1","2","3","4"},swID],Print["Set IBP4_SHARD_ID to 1,2,3,4"];Quit[1]];
swShard=ToExpression[swID];swSmoke=Environment["DCI_SEED_SMOKE"]==="1";
swOut=Environment["DCI_SEED_OUT"];
If[!StringQ[swOut] || swOut==="",swOut=FileNameJoin[{swHome,"work","seed-"<>swTag}]];
swOut=FileNameJoin[{swOut,"shard"<>swID}];
If[DirectoryQ[swOut],Print["Use a new DCI_SEED_OUT directory"];Quit[1]];
swAssert[b_,m_]:=If[!TrueQ[b],Print[m];Quit[1]];
SingularInterfacePath="";IBP4UseContactLaurent=True;
Get[FileNameJoin[{swHome,"legacy","IBP4loop.wl"}]];
Get[FileNameJoin[{swHome,"legacy","IBP4SeedDomain.wl"}]];
Get[FileNameJoin[{swHome,"legacy","IBP4GeneratorVersion.wl"}]];
Get[FileNameJoin[{swHome,"legacy","IBP4FactorCache.wl"}]];
swBlocks=Get[FileNameJoin[{swHome,"Operators.wl"}]];
swAssert[Hash[swBlocks,"SHA256"]===Get[FileNameJoin[{swHome,"OperatorAudit.wl"}]]["OperatorHash"],
 "Operator blocks differ from the degree-audited snapshot"];
swFingerprint=IBP4GeneratorFingerprint[];
swAssert[swFingerprint===Get[FileNameJoin[{swHome,"OperatorAudit.wl"}]]["GeneratorFingerprint"],
 "Frozen generator fingerprint mismatch"];
swFile=FileNameJoin[{swData,"provenance","campaign",swTag,"SeedData.wl"}];
swAssert[FileExistsQ[swFile],"Missing SeedData.wl; fetch.py --all first"];
swRows=Get[swFile];CreateDirectory[swOut,CreateIntermediateDirectories->True];swAudit={};
Do[
 swRow=swRows[[swI]];swOps=swBlocks[[1,1,swRow["DegreeID"]]][[swRow["OperatorIDs"]]];
 swTemplates=Lookup[swRow,"AllowedDenominatorTemplates",Missing["Absent"]];
 swAssert[ibp4DenominatorTemplatesQ[swTemplates],"Explicit seed domain required"];
 swAssert[And@@(HomogeneousQ[#/.pro[_]->0]===swRow["Degree"]& /@ swOps),"Operator degree mismatch"];
 swIDs=Range[swShard,Length[swRow["Seeds"]],4];
 If[swSmoke,swIDs=Take[swIDs,UpTo[1]]];
 swGroups=Partition[swIDs,UpTo[100]];
 Do[
  swRelations={};swRejected=0;swZero=0;swAttempts=0;swDirect=0;
  Do[swSeed=swRow["Seeds"][[swJ]];
   swAssert[ibp4SeedSupportFitsQ[{Take[List@@swSeed,22]},swTemplates],"Positive seed ISP"];
   swAssert[factorSeedQ[Take[List@@swSeed,22],swRow["Degree"]],"Seed/operator conformal degree mismatch"];
   Do[swAttempts++;swRelation=factorCachedIBP[swOp,Propagators4,swSeed];
    If[swAttempts===1,
     swReference=Operator2IBP[swOp,Propagators4,swSeed];
     swAssert[swReference===swRelation ||
      (FreeQ[{swReference,swRelation},False|$Failed] && Together[swReference-swRelation]===0),
      "Cached/direct operator action mismatch"];swDirect++];
    Which[swRelation===$Failed,swAssert[False,"Operator action failed"],
     swRelation===False,swRejected++,swRelation===0,swZero++,True,
     swInts=Union[Cases[{swRelation},_G,Infinity]];
     swAssert[FreeQ[swRelation,_sp] && And@@(Length[List@@#]===26 &&
       Max[(List@@#)[[17;;22]]]<=2 && Max[(List@@#)[[20;;22]]]<=0& /@ swInts),"Invalid IBP output"];
     swAssert[ibp4SeedSupportFitsQ[Join[{Take[List@@swSeed,22]},Take[List@@#,22]& /@ swInts],swTemplates],
       "Output outside allowed supersector"];
     AppendTo[swRelations,swRelation]],{swOp,swOps}],{swJ,swGroups[[swB]]}];
  swRelations=DeleteDuplicates[swRelations];
  swName="operator"<>ToString[swI]<>"_batch"<>ToString[swB];
  Put[swRelations,FileNameJoin[{swOut,swName<>".wl"}]];
  swRecord=<|"RowID"->swI,"DegreeID"->swRow["DegreeID"],"Degree"->swRow["Degree"],
   "OperatorIDs"->swRow["OperatorIDs"],"SeedIDs"->swGroups[[swB]],
   "SeedHash"->Hash[swRow["Seeds"][[swGroups[[swB]]]],"SHA256"],
   "GeneratorFingerprint"->swFingerprint,"Applications"->swAttempts,"Rejected"->swRejected,
   "Zero"->swZero,"Relations"->Length[swRelations],"DirectActionChecks"->swDirect|>;
  Put[swRecord,FileNameJoin[{swOut,swName<>"_audit.wl"}]];AppendTo[swAudit,swRecord];
  Print[{swShard,swI,swB,swAttempts,Length[swRelations]}],{swB,Length[swGroups]}],{swI,Length[swRows]}];
Put[<|"Campaign"->swTag,"Shard"->swShard,"SmokeOnly"->swSmoke,
 "Complete"->True,"SeedDataHash"->Hash[swRows,"SHA256"],"Batches"->swAudit|>,
 FileNameJoin[{swOut,"Summary.wl"}]];Quit[];
