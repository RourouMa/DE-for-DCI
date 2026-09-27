(* Reusable highest-loop route: full physical equations remain immutable;
   only query coordinates are reconstructed. A changed pool requires a fresh run. *)
Options[RunPhysicalCoordinateDE]={"OutputDirectory"->None,"MaxRounds"->20,"Workers"->4,
 "MasterCountUserUpperBound"->Automatic,"GrowthChainThreshold"->3,"VerificationPoint"->{11,17},"Provenance"-><||>,"ExtraFiniteCandidates"->{},"FiniteReferenceBasis"->{},"FiniteCoverPolicy"->"PreserveActualSpan","MaxRelativeCoverExcess"->Automatic,"CanonicalPoolCache"->None};
RunPhysicalCoordinateDE[f_Association,original_List,equations_List,OptionsPattern[]]:=Module[
 {out=OptionValue["OutputDirectory"],threads=OptionValue["Workers"],bound=Replace[OptionValue["MasterCountUserUpperBound"],Automatic->Infinity],
 threshold=OptionValue["GrowthChainThreshold"],point=OptionValue["VerificationPoint"],dir,cacheDir,indexFile,poolHash,
 meta,reference,basis=original,parentFile,physical,selection,rank,inputRank,result,certificate,status,history={},growth=<||>,images,
 n,closed=False,matrices=<||>,reason="RoundLimit",sourceFile,benchmarkFile,initial,round,manifestFile,primitive,rankCertificate,
 coverPolicy=OptionValue["FiniteCoverPolicy"],preparedIndex,preparedOrigin=None},
 If[!StringQ[out]||!MemberQ[$Packages,"FiniteFlow`"]||Length[point]=!=Length[f["Variables"]]||!AllTrue[original,TrueQ[FiniteIntegralQ[f,#]]&],
  Return[fail["CoordinateCampaignInput","Initialize FiniteFlow, supply an output directory, a regular point and native-finite original inputs."]]];
 If[!IntegerQ[threshold]||threshold<1,Return[fail["GrowthChainThreshold","Use a positive growth-step threshold."]]];
 If[!MemberQ[{"PreserveActualSpan","LowPoleClosureFirst"},coverPolicy],Return[fail["FiniteCoverPolicy","Use PreserveActualSpan or LowPoleClosureFirst."]]];
 If[OptionValue["MaxRelativeCoverExcess"]=!=Automatic&&(!MatchQ[OptionValue["MaxRelativeCoverExcess"],_Integer|_Rational|_Real]||!TrueQ[OptionValue["MaxRelativeCoverExcess"]>=0]),Return[fail["ExtraCoverBudget","Use Automatic or a finite nonnegative relative cover excess (cover count minus actual rank, divided by actual rank)."]]];
 If[FileExistsQ[FileNameJoin[{out,"Campaign.wl"}]],Return[fail["CoordinateCampaignExists","Use a fresh directory; retain completed certificates."]]];
 If[!DirectoryQ[out],CreateDirectory[out,CreateIntermediateDirectories->True]];
 If[StringQ[OptionValue["CanonicalPoolCache"]],
  preparedIndex=Get[OptionValue["CanonicalPoolCache"]];
  If[!AssociationQ[preparedIndex]||!FileExistsQ[Lookup[preparedIndex,"File",""]]||FileHash[preparedIndex["File"],"SHA256"]=!=preparedIndex["FileSHA256"],Return[fail["PreparedPhysicalPoolHash","The prepared physical pool file must match its SHA256 index."]]];
  Clear[poolRows,poolColumns,poolMetadata];Get[preparedIndex["File"]];
  If[!ListQ[poolRows]||!ListQ[poolColumns]||!AssociationQ[poolMetadata]||Lookup[poolMetadata["Family"],"Hash",None]=!=f["Hash"]||Hash[poolRows,"SHA256"]=!=preparedIndex["FullPoolHash"],Return[fail["PreparedPhysicalPoolFamily","Prepared rows, family and declared physical-pool hash must agree."]]];
  If[equations=!={}&&Hash[DeleteCases[Union[equations],0],"SHA256"]=!=preparedIndex["FullPoolHash"],Return[fail["PreparedPhysicalPoolInput","Nonempty equations must equal the prepared canonical pool."]]];
  poolHash=preparedIndex["FullPoolHash"];preparedOrigin=<|"Index"->OptionValue["CanonicalPoolCache"],"IndexSHA256"->FileHash[OptionValue["CanonicalPoolCache"],"SHA256"],"FileSHA256"->preparedIndex["FileSHA256"],"PriorMetadata"->poolMetadata|>,
  poolRows=DeleteCases[Union[canonExpr[f,#]& /@ equations],0];
  If[AnyTrue[poolRows,FailureQ],Return[fail["CoordinatePoolCanonicalization","Physical pool contains inadmissible expressions."]]];
  poolHash=Hash[poolRows,"SHA256"];poolColumns=Join[SortBy[support[poolRows],simpleKey[f,#]&],sources[poolRows]]];
 poolMetadata=<|"Family"->f,"FullPoolHash"->poolHash,"ImplementationHash"->$implementationHash,"SourceInformationRetained"->True,"Provenance"->OptionValue["Provenance"],"PreparedPhysicalPoolOrigin"->preparedOrigin|>;
 cacheDir=FileNameJoin[{out,"full-pool-cache"}];If[!DirectoryQ[cacheDir],CreateDirectory[cacheDir]];
 sourceFile=FileNameJoin[{cacheDir,"CanonicalPool.mx"}];DumpSave[sourceFile,{poolRows,poolColumns,poolMetadata}];
 indexFile=FileNameJoin[{cacheDir,"Index.wl"}];Put[<|"File"->sourceFile,"FileSHA256"->FileHash[sourceFile,"SHA256"],"FullPoolHash"->poolHash|>,indexFile];
 benchmarkFile=FileNameJoin[{out,"EmptyBenchmark.mx"}];manifestFile=FileNameJoin[{out,"EmptySourceManifest.mx"}];
 Block[{benchmark=<|"Rows"->{},"Columns"->{},"Queries"->{}|>},DumpSave[benchmarkFile,benchmark]];
 Block[{sourceManifest=<|"OriginalEquationsHash"->Hash[{},"SHA256"],"FullPoolHash"->poolHash,"FullPoolCacheIndex"->indexFile,"Provenance"->OptionValue["Provenance"],"SourceInformationRetained"->True|>},DumpSave[manifestFile,sourceManifest]];
 meta=<|"FamilyHash"->f["Hash"],"FullPoolHash"->poolHash,"ImplementationHash"->$implementationHash,"FullReferenceBenchmark"->benchmarkFile,"FullReferenceSourceManifest"->manifestFile,
 "FullReferenceQueries"->{} ,"FullPoolNumericalRules"->{},"Point"->point,"Prime"->FiniteFlow`FFPrimeNo[0]|>;reference=meta;
 Clear[poolRows,poolColumns];
 initial=<|"Basis"->original,"OriginalInputs"->True,"FullPoolHash"->poolHash,"ImplementationHash"->$implementationHash|>;
 parentFile=FileNameJoin[{out,"InitialInput.wl"}];Put[initial,parentFile];
 Do[
  dir=FileNameJoin[{out,"round"<>ToString[round]}];physical=preparePhysicalConstruction[f,basis,dir,meta];If[FailureQ[physical],reason=physical;Break[]];
  reference=updatePhysicalCoordinateReference[f,Union[physical["Required"],support[canonExpr[f,#]& /@ Join[OptionValue["ExtraFiniteCandidates"],OptionValue["FiniteReferenceBasis"]]]],reference,indexFile,FileNameJoin[{dir,"reference"}]];
  If[FailureQ[reference],reason=reference;Break[]];
  Block[{coordinateReference=reference},DumpSave[FileNameJoin[{dir,"reference","Reference.mx"}],coordinateReference]];
  physical=Join[physical,<|"ExtraFiniteCandidates"->OptionValue["ExtraFiniteCandidates"],"FiniteReferenceBasis"->OptionValue["FiniteReferenceBasis"],"CoordinateThreads"->threads,"FiniteCoverPolicy"->coverPolicy,"MaxRelativeCoverExcess"->OptionValue["MaxRelativeCoverExcess"]|>];selection=selectLowPolePhysicalBasis[f,physical,reference,dir,round];If[FailureQ[selection],reason=selection;Break[]];
  rank=selection["Report"]["SampledActualRank"];inputRank=selection["Report"]["InputRank"];
  closed=(rank===inputRank&&inputRank===Length[basis]&&representativePoleLimitsQ[f,basis]);
  images=(((selection["PhysicalRows"]/.Thread[f["Variables"]->point])/.Dispatch[reference["FullPoolNumericalRules"]])/._BoundaryIntegral->0);
  images=growthChainPointRows[images,reference["Prime"]];If[FailureQ[images],reason=images;Break[]];
  growth=AssessGrowthChains[f,growth,images,round,threshold];Put[growth,FileNameJoin[{dir,"GrowthChainAudit.wl"}]];
  If[rank>bound||(!closed&&TrueQ[growth["Triggered"]]),
   reason="RelationRepairRequired";status=<|"Stage"->reason,"Round"->round,"InputRank"->inputRank,"JointRankLowerBound"->rank,"BoundExceeded"->(rank>bound),"ChainTriggered"->growth["Triggered"],"NextDEInputAccepted"->False|>;
   Export[FileNameJoin[{dir,"Status.json"}],status,"RawJSON"];Put[growth["RepairTargets"],FileNameJoin[{out,"RepairTargets.wl"}]];Break[]];
  result=projectRowsInPhysicalBasis[f,selection["PhysicalRows"],If[closed,physical["PhysicalInput"],selection["PhysicalBasis"]],reference,dir,threads];
  If[FailureQ[result],reason=result;Break[]];
  If[!closed&&Length[selection["Basis"]]>rank,
   rankCertificate=projectRowsInPhysicalBasis[f,selection["PhysicalRows"],selection["ActualPhysicalBasis"],reference,FileNameJoin[{dir,"actual-rank"}],threads];
   If[FailureQ[rankCertificate],reason=rankCertificate;Break[]]];
  certificate=<|"Round"->round,"Basis"->If[closed,basis,selection["Basis"]],"PhysicalBasis"->If[closed,physical["PhysicalInput"],selection["PhysicalBasis"]],
   "PhysicalRows"->selection["PhysicalRows"],"Weights"->result["Weights"],"InputRank"->inputRank,"RationalRank"->rank,"FullPoolHash"->poolHash,
   "ImplementationHash"->$implementationHash,"FullPoolProjectionAgreement"->True,"FinitenessVerified"->True,"ParentCertificate"->parentFile,"ParentSHA256"->FileHash[parentFile,"SHA256"],
   "ActualRankCertificate"->FileNameJoin[Join[{dir},If[!closed&&Length[selection["Basis"]]>rank,{"actual-rank"},{}],{"PhysicalCoordinates.wl"}]],
   "HighestLoopCandidateClosed"->closed,"FiniteCoverPolicy"->coverPolicy,"CoverBasisCount"->Length[If[closed,basis,selection["Basis"]]],"SourceManifest"->reference["FullReferenceSourceManifest"]|>;
  parentFile=FileNameJoin[{dir,"CoordinateCertificate.wl"}];Put[certificate,parentFile];
  status=<|"Stage"->If[closed,"IndependentVerificationRequired","RoundVerified"],"Round"->round,"InputRank"->inputRank,"RationalJointRank"->rank,
   "CoverBasisCount"->Length[certificate["Basis"]],"FiniteCoverPolicy"->coverPolicy,"CoverPreservesActualSpan"->(Length[certificate["Basis"]]===rank),
   "RelativeCoverExcess"->If[rank===0,0,N[(Length[certificate["Basis"]]-rank)/rank]],"MaxRelativeCoverExcess"->selection["Report"]["MaxRelativeCoverExcess"],
   "ConstantFiniteBasis"->FreeQ[certificate["Basis"],Alternatives@@f["Variables"]],"ConnectedPoleAudit"->KeyDrop[connectedPoleAudit[f,certificate["Basis"]],"HighPowerConnectedAtoms"],"FullPoolHash"->poolHash|>;
  AppendTo[history,status];Export[FileNameJoin[{dir,"Status.json"}],status,"RawJSON"];Print[status];
  basis=certificate["Basis"];
  If[closed,n=Length[basis];matrices=Association@MapIndexed[#1->Take[result["Weights"],{n+(First[#2]-1)n+1,n+First[#2]n}]&,f["Variables"]];reason="IndependentVerificationRequired";Break[]],
 {round,1,OptionValue["MaxRounds"]}];
 status=<|"Status"->reason,"Family"->f,"OriginalInputs"->original,"Basis"->basis,"Matrices"->matrices,"History"->history,"GrowthChainAudit"->growth,
 "FullPoolHash"->poolHash,"FullPoolCacheIndex"->indexFile,"Reference"->reference,"ImplementationHash"->$implementationHash,"HighestLoopCandidateClosed"->closed,"FiniteCoverPolicy"->coverPolicy,
 "HighestLoopIndependentlyVerified"->False,"SourcesRetained"->True,"LowerLoopComputed"->False,"SourceCoefficientsPending"->True|>;
 Put[status,FileNameJoin[{out,"Campaign.wl"}]];Export[FileNameJoin[{out,"Status.json"}],<|"Status"->ToString[reason,InputForm],"BasisCount"->Length[basis],"Rounds"->Length[history],"HighestLoopCandidateClosed"->closed,"HighestLoopIndependentlyVerified"->False,"FullPoolHash"->poolHash|>,"RawJSON"];status];
