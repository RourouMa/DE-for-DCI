(* Extend numerical reference from the complete immutable physical pool.
   Preserve full source rows and their provenance before the highest-loop quotient. *)
readSavedCoordinateReference[file_String]:=Block[{coordinateReference},Get[file];coordinateReference];
updatePhysicalCoordinateReference[f_Association,required_List,prior_Association,cacheIndex_String,dir_String]:=Module[
 {savedFile,index,known,missing,oldBenchmark,oldManifest,witness,cols,graph,in,sys,learn,values,numericRules,
  ids,count,newRows,rows,present,selectedColumns,queries,referenceRules,benchmarkFile,manifestFile,
  nextBenchmark,nextManifest,result,started=AbsoluteTime[]},
 If[!DirectoryQ[dir],CreateDirectory[dir,CreateIntermediateDirectories->True]];
 savedFile=FileNameJoin[{dir,"Reference.mx"}];
 If[FileExistsQ[savedFile],result=readSavedCoordinateReference[savedFile];
  If[result["FullPoolHash"]=!=prior["FullPoolHash"]||result["FamilyHash"]=!=f["Hash"],Return[Failure["CoordinateReferenceCacheMismatch",<||>]]];
  known=Union[result["FullReferenceQueries"],ConformalIBP`Private`support[Last /@ result["FullPoolNumericalRules"]]];
  If[Complement[required,known]==={},Return[result],Return[Failure["CoordinateReferenceCacheMissingTargets",<||>]]]];
 known=Union[prior["FullReferenceQueries"],ConformalIBP`Private`support[Last /@ prior["FullPoolNumericalRules"]]];
 missing=Complement[required,known];If[missing==={},Return[prior]];
 oldBenchmark=readCoordinateBenchmark[prior["FullReferenceBenchmark"]];oldManifest=readCoordinateManifest[prior["FullReferenceSourceManifest"]];
 If[oldManifest["FullPoolHash"]=!=prior["FullPoolHash"]||oldManifest["OriginalEquationsHash"]=!=Hash[oldBenchmark["Rows"],"SHA256"],Return[Failure["CoordinateParentProvenance",<||>]]];
 index=Get[cacheIndex];If[index["FullPoolHash"]=!=prior["FullPoolHash"]||index["FileSHA256"]=!=FileHash[index["File"],"SHA256"],Return[Failure["CoordinateFullPoolCache",<||>]]];
 Get[index["File"]];
 witness=Unique["coordinateReferenceWitness"];cols=Join[{witness},poolColumns,Complement[missing,poolColumns]];
 Print[<|"At"->DateString[Now,"ISODateTime"],"Event"->"CoordinateFullPhysicalPoolLearning","Rows"->Length[poolRows],"MissingTargets"->Length[missing]|>];
 FiniteFlow`FFNewGraph[graph];FiniteFlow`FFGraphInputVars[graph,in,f["Variables"]];
 FiniteFlow`FFAlgSparseSolver[graph,sys,{in},f["Variables"],#==0& /@ Prepend[poolRows,witness-First[missing]],cols,"NeededVars"->Append[missing,witness]];
 FiniteFlow`FFSolverSparseOutput[graph,sys];FiniteFlow`FFGraphOutput[graph,sys];learn=FiniteFlow`FFSparseSolverLearn[graph,cols];
 If[!ListQ[learn],FiniteFlow`FFDeleteGraph[graph];Return[Failure["CoordinateFullReferenceLearn",<||>]]];
 values=FiniteFlow`FFGraphEvaluateMany[graph,{prior["Point"]},"NThreads"->1];
 If[!MatchQ[values,{_List}],FiniteFlow`FFDeleteGraph[graph];Return[Failure["CoordinateFullReferencePoint",<||>]]];
 numericRules=Select[FiniteFlow`FFSparseSolverSol[First[values],learn],MatchQ[First[#],_G|_BoundaryIntegral]&];
 count=FiniteFlow`FFSparseSolverMarkAndSweepEqs[graph,sys];ids=FiniteFlow`FFSolverIndepEqs[graph,sys];FiniteFlow`FFDeleteGraph[graph];
 If[!ListQ[ids]||Length[ids]=!=count||!AllTrue[ids,1<=#<=Length[poolRows]+1&],Return[Failure["CoordinateReferenceDependencyRows",<||>]]];
 newRows=poolRows[[Select[ids,#>1&]-1]];rows=Union[oldBenchmark["Rows"],newRows];
 present=Association[(#->True)& /@ Union[ConformalIBP`Private`support[rows],ConformalIBP`Private`sources[rows]]];
 selectedColumns=Select[poolColumns,KeyExistsQ[present,#]&];Clear[poolRows,poolColumns,oldBenchmark,newRows,present];
 queries=Union[prior["FullReferenceQueries"],missing];referenceRules=Normal[Join[Association[prior["FullPoolNumericalRules"]],Association[numericRules]]];
 benchmarkFile=FileNameJoin[{dir,"Benchmark.mx"}];manifestFile=FileNameJoin[{dir,"SourceManifest.mx"}];
 nextBenchmark=<|"Rows"->rows,"Columns"->selectedColumns,"Queries"->queries|>;
 nextManifest=<|"OriginalEquationsHash"->Hash[rows,"SHA256"],"FullPoolHash"->prior["FullPoolHash"],
  "ParentManifest"->prior["FullReferenceSourceManifest"],"ParentManifestSHA256"->FileHash[prior["FullReferenceSourceManifest"],"SHA256"],
  "FullPoolCacheIndex"->cacheIndex,"NewQueries"->missing,"NewLearningInformation"->learn,"NewNumericalRules"->numericRules,
  "SelectedEquationIndicesInAugmentedPool"->ids,"AuxiliaryWitness"->witness,"AuxiliaryWitnessRowExcluded"->True,
  "Point"->prior["Point"],"Prime"->prior["Prime"],"SourceInformationRetained"->True,"SourceCoefficientsPending"->True|>;
 Block[{benchmark=nextBenchmark},DumpSave[benchmarkFile,benchmark]];
 Block[{sourceManifest=nextManifest},DumpSave[manifestFile,sourceManifest]];
 result=Join[prior,<|"FullReferenceBenchmark"->benchmarkFile,"FullReferenceSourceManifest"->manifestFile,"FullReferenceQueries"->queries,"FullPoolNumericalRules"->referenceRules|>];
 Block[{coordinateReference=result},DumpSave[savedFile,coordinateReference]];
 Export[FileNameJoin[{dir,"Report.json"}],<|"FullPhysicalPoolUsed"->True,"Rows"->Length[rows],"NewQueries"->Length[missing],
  "FullPoolHash"->prior["FullPoolHash"],"SourceInformationRetained"->True,"LowerLoopIBPOrDEComputed"->False,"Seconds"->N[AbsoluteTime[]-started]|>,"RawJSON"];
 Print[<|"At"->DateString[Now,"ISODateTime"],"Event"->"CoordinateFullReferenceSaved","MissingTargets"->Length[missing],"SelectedRows"->Length[rows]|>];result];
