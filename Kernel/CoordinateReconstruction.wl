(* Record native FiniteFlow degree discovery separately from sampling. *)
reconstructWithDegreeAudit[graph_,variables_List,threads_Integer,dir_String,initialLimit_:200]:=Module[
 {discovery,limit,limits=DeleteDuplicates[{initialLimit,Max[initialLimit,400]}],file,t,values=$Failed,raw,entries,report},
 Do[
  t=AbsoluteTime[];
  Print[<|"At"->DateString[Now,"ISODateTime"],"Event"->"ProjectedDegreeDiscoveryStarted","MaxDegree"->limit,"Threads"->threads|>];
  discovery=FiniteFlow`FFAllDegrees[graph,threads,"MaxDegree"->limit];
  If[!ListQ[discovery],Put[discovery,FileNameJoin[{dir,"DegreeFailure-"<>ToString[limit]<>".wl"}]];Continue[]];
  file=FileNameJoin[{dir,"ProjectedDegrees.bin"}];FiniteFlow`FFDumpDegrees[graph,file];
  raw=BinaryReadList[file,"UnsignedInteger64",ByteOrdering->-1];entries=Partition[Drop[raw,2],2+4Length[variables]];
  report=<|"Coefficients"->Length[entries],"MaximumNumeratorDegree"->Max[entries[[All,1]]],
   "MaximumDenominatorDegree"->Max[entries[[All,2]]],"MaxDegreeBudget"->limit,"DegreeDiscoverySeconds"->N[AbsoluteTime[]-t]|>;
  Export[FileNameJoin[{dir,"DegreeReport.json"}],report,"RawJSON"];
  Print[Join[<|"At"->DateString[Now,"ISODateTime"],"Event"->"ProjectedSamplingStarted"|>,report]];
  values=FiniteFlow`FFReconstructFunction[graph,variables,"Degrees"->file,"NThreads"->threads,"MaxPrimes"->80,"MaxDegree"->limit];
  Break[],{limit,limits}];
 values];
