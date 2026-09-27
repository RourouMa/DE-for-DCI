(* Point selection is provisional. Direct rational coordinates are required before acceptance. *)
selectLowPolePhysicalBasis[f_Association,physical_Association,reference_Association,out_String,round_Integer]:=Module[
 {physicalRows,candidates,candidatePhysical,keep,point,prime,image,images,candidateImages,atoms,mod,m,cm,nonzero,pivots,rr,actual,eligible,candidateRank,selected,chosen,poleAudit,report,known,queries,referenceRules,cancellation,frame,framePhysical,frameCoordinates,projectedPhysical,frameAtoms,usingFrame=False,
 policy=Lookup[physical,"FiniteCoverPolicy","PreserveActualSpan"],candidateMatrix,candidatePivots,inverse,pointWeights,used,spans,actualRows,
 relativeBudget,extraBudget,wideCount,widePole,inside,insideBasis,retained,residuals={},trialResidual,trialRank,ids},
 queries=reference["FullReferenceQueries"];referenceRules=reference["FullPoolNumericalRules"];
 known=Union[queries,ConformalIBP`Private`support[Last /@ referenceRules]];
physicalRows=Join[physical["PhysicalInput"],physical["PhysicalDE"]];
frame=Lookup[physical,"FiniteReferenceBasis",{}];
If[frame=!={},
 If[!AllTrue[frame,cachedFiniteCandidateQ[f,#]&],Return[Failure["NonfiniteReferenceBasis",<||>]]];
 framePhysical=ConformalIBP`Private`canonExpr[f,#]& /@ frame;
 frameCoordinates=projectRowsInPhysicalBasis[f,physicalRows,framePhysical,reference,FileNameJoin[{out,"finite-reference-coordinates"}],Lookup[physical,"CoordinateThreads",4]];
 If[FailureQ[frameCoordinates],Return[frameCoordinates]];
 projectedPhysical=ConformalIBP`Private`canonicalLinear /@ (frameCoordinates["Weights"].frame);
 frameAtoms=ConformalIBP`Private`support[framePhysical];
 candidates=DeleteDuplicates[Join[frame,projectedPhysical,
  ConformalIBP`Private`physicalConstantCandidates[f,projectedPhysical],
  Select[Join[physical["Basis"],Lookup[physical,"ExtraFiniteCandidates",{}],queries],Complement[ConformalIBP`Private`support[ConformalIBP`Private`canonExpr[f,#]],frameAtoms]==={}&]]];
 candidates=Select[candidates,cachedFiniteCandidateQ[f,#]&];usingFrame=True,
 candidates=DeleteDuplicates[Join[physical["Basis"],Lookup[physical,"ExtraFiniteCandidates",{}],queries,If[policy==="LowPoleClosureFirst",physical["RawDerivative"],{}],ConformalIBP`Private`physicalConstantCandidates[f,Join[physical["Basis"],physical["RawDerivative"]]]]];
 candidates=Select[candidates,(policy==="LowPoleClosureFirst"||FreeQ[#,Alternatives@@f["Variables"]])&&cachedFiniteCandidateQ[f,#]&]];
cancellation=constantPoleCancellationCandidates[f,candidates];If[FailureQ[cancellation],Return[cancellation]];
candidates=DeleteDuplicates[Join[candidates,cancellation["Candidates"]]];
candidates=Select[candidates,representativePoleLimitsQ[f,#]&];
If[candidates==={},Return[fail["PropagatorPowerLimitedCoverMissing","No finite candidate satisfies external-loop powers <=3 and loop-loop powers <=2; add finite combinations or physical relations."]]];
candidates=SortBy[candidates,If[policy==="LowPoleClosureFirst",
 Join[Most[ConformalIBP`Private`finiteRepresentativeCost[f,#]],{Boole[!ConformalIBP`Private`constantCombinationQ[#]],LeafCount[#],#}],
 Prepend[ConformalIBP`Private`finiteRepresentativeCost[f,#],Boole[!ConformalIBP`Private`constantCombinationQ[#]]]]&];
candidatePhysical=ConformalIBP`Private`canonExpr[f,#]& /@ candidates;
keep=Select[Range[Length[candidates]],Complement[ConformalIBP`Private`support[candidatePhysical[[#]]],known]==={}&];
candidates=candidates[[keep]];candidatePhysical=candidatePhysical[[keep]];
If[Complement[ConformalIBP`Private`support[physicalRows],known]=!={},Return[Failure["MissingCandidateReference",<||>]]];
point=Thread[f["Variables"]->reference["Point"]];prime=reference["Prime"];
image[rows_]:=(((rows/.point)/.Dispatch[referenceRules])/._BoundaryIntegral->0);
images=image[physicalRows];candidateImages=image[candidatePhysical];atoms=ConformalIBP`Private`support[{images,candidateImages}];
mod[q_]:=With[{v=Together[q]},If[MatchQ[v,_Integer|_Rational]&&Mod[Denominator[v],prime]=!=0,Mod[Numerator[v]PowerMod[Denominator[v],-1,prime],prime],$Failed]];
m=Map[mod,ConformalIBP`Private`coeff[images,atoms],{2}];cm=Map[mod,ConformalIBP`Private`coeff[candidateImages,atoms],{2}];
If[!MatrixQ[m,IntegerQ]||!MatrixQ[cm,IntegerQ],Return[Failure["CandidatePointPole",<||>]]];
nonzero[a_]:=Select[a,AnyTrue[#,UnequalTo[0]]&];
pivots[a_]:=First[FirstPosition[#,v_Integer/;v=!=0,Missing[],{1},Heads->False]]& /@ a;
rr=nonzero[RowReduce[m,Modulus->prime]];actual=pivots[rr];
relativeBudget=Replace[Lookup[physical,"MaxRelativeCoverExcess",Automatic],Automatic->3/2];
extraBudget=Floor[Length[rr] relativeBudget];
If[!VectorQ[actual,IntegerQ]||!AllTrue[actual,1<=#<=Length[atoms]&],Return[Failure["CandidatePivotWitness",<||>]]];
actualRows=pivots[nonzero[RowReduce[Transpose[m],Modulus->prime]]];
If[policy==="LowPoleClosureFirst",
 eligible=pivots[nonzero[RowReduce[Transpose[cm],Modulus->prime]]];
 If[eligible==={},Return[fail["SimpleFiniteCoverMissing","No independent finite candidate is available."]]];
 candidateMatrix=cm[[eligible]];candidatePivots=pivots[nonzero[RowReduce[candidateMatrix,Modulus->prime]]];
 inverse=Take[RowReduce[Join[candidateMatrix[[All,candidatePivots]],IdentityMatrix[Length[eligible]],2],Modulus->prime],All,-Length[eligible]];
 pointWeights=Mod[m[[All,candidatePivots]].inverse,prime];
 spans=Mod[pointWeights.candidateMatrix-m,prime]===ConstantArray[0,Dimensions[m]];
 If[!spans,Return[fail["SimpleFiniteCoverIncomplete","The available simple finite representatives do not cover the actual rows."]]];
 used=Select[Range[Length[eligible]],AnyTrue[pointWeights[[All,#]],UnequalTo[0]]&];selected=eligible[[used]];wideCount=Length[selected];
 If[wideCount>Length[rr]+extraBudget,
  widePole=connectedPoleAudit[f,candidates[[selected]]]["MaximumConnectedPropagatorPower"];
  inside=Select[Range[Length[candidates]],Mod[cm[[#]]-cm[[#,actual]].rr,prime]===ConstantArray[0,Length[atoms]]&];
  If[inside==={},Return[fail["SimpleCoverCountTradeoff","No compact finite alternative is available within the extra-direction budget."]]];
  insideBasis=inside[[pivots[nonzero[RowReduce[Transpose[cm[[inside]]],Modulus->prime]]]]];
  If[Length[insideBasis]=!=Length[rr],Return[fail["SimpleCoverCountTradeoff","Simple coverage needs too many extra directions; add finite candidates or repair relations."]]];
  retained={};Do[
   trialResidual=Mod[cm[[id]]-cm[[id,actual]].rr,prime];
   trialRank=Length[nonzero[RowReduce[Append[residuals,trialResidual],Modulus->prime]]];
   If[trialRank<=extraBudget,AppendTo[retained,id];residuals=nonzero[RowReduce[Append[residuals,trialResidual],Modulus->prime]]],{id,selected}];
  ids=Union[retained,insideBasis];eligible=ids[[pivots[nonzero[RowReduce[Transpose[cm[[ids]]],Modulus->prime]]]]];
  candidateMatrix=cm[[eligible]];candidatePivots=pivots[nonzero[RowReduce[candidateMatrix,Modulus->prime]]];
  inverse=Take[RowReduce[Join[candidateMatrix[[All,candidatePivots]],IdentityMatrix[Length[eligible]],2],Modulus->prime],All,-Length[eligible]];
  pointWeights=Mod[m[[All,candidatePivots]].inverse,prime];
  spans=Mod[pointWeights.candidateMatrix-m,prime]===ConstantArray[0,Dimensions[m]];
  used=Select[Range[Length[eligible]],AnyTrue[pointWeights[[All,#]],UnequalTo[0]]&];selected=eligible[[used]];
  If[!spans||Length[selected]>Length[rr]+extraBudget||connectedPoleAudit[f,candidates[[selected]]]["MaximumConnectedPropagatorPower"]>widePole,
   Return[fail["SimpleCoverCountTradeoff","The count target cannot be met without worsening connected powers; add simple finite candidates or repair relations."]]]];
 candidateRank=Length[selected],
 eligible=Select[Range[Length[candidates]],Mod[cm[[#]]-cm[[#,actual]].rr,prime]===ConstantArray[0,Length[atoms]]&];
 candidateRank=If[eligible==={},0,Length[nonzero[RowReduce[cm[[eligible]],Modulus->prime]]]];
 selected=If[eligible==={},{},eligible[[pivots[nonzero[RowReduce[Transpose[cm[[eligible]]],Modulus->prime]]]]]];
 spans=candidateRank===Length[rr];wideCount=Length[selected]];
chosen=candidates[[selected]];poleAudit=ConformalIBP`Private`connectedPoleAudit[f,chosen];
report=<|"Round"->round,"SampledActualRank"->Length[rr],"InputRank"->Length[nonzero[RowReduce[Take[m,Length[physical["Basis"]]],Modulus->prime]]],
 "FiniteCandidates"->Length[candidates],"FiniteConstantCandidates"->Count[ConformalIBP`Private`constantCombinationQ /@ candidates,True],"FiniteReferenceBasisUsed"->usingFrame,"ReferenceBasisCount"->Length[frame],"NumericallyEligibleCandidates"->Length[eligible],"SampledCandidateRank"->candidateRank,"BasisCount"->Length[chosen],
 "FiniteCoverPolicy"->policy,"CoverPreservesActualSpan"->(Length[chosen]===Length[rr]),"ExtraCoverDirections"->(Length[chosen]-Length[rr]),
 "MaxRelativeCoverExcess"->N[relativeBudget],"MaxRelativeCoverExcessExact"->ToString[relativeBudget,InputForm],
 "RelativeCoverExcess"->If[Length[rr]===0,0,N[(Length[chosen]-Length[rr])/Length[rr]]],"DerivedExtraCoverDirectionsLimit"->extraBudget,"UnconstrainedSimpleCoverCount"->wideCount,
 "NumericallySpans"->spans,"EveryCandidateFinite"->AllTrue[chosen,FiniteIntegralQ[f,#]&],
 "ConstantPoleCancellationAudit"->cancellation["Audit"],"AllCoefficientsConstant"->FreeQ[chosen,Alternatives@@f["Variables"]],"ConnectedPoleAudit"->KeyDrop[poleAudit,"HighPowerConnectedAtoms"],
 "ExactPhysicalCoordinateReconstructionPending"->True,"AcceptedAsNextDEInput"->False,"FullPoolHash"->reference["FullPoolHash"]|>;
Put[<|"Report"->report,"Basis"->chosen,"PhysicalBasis"->candidatePhysical[[selected]],"PhysicalRows"->physicalRows,"SelectedCandidateIndices"->selected,
 "FullPoolHash"->reference["FullPoolHash"]|>,FileNameJoin[{out,"CandidateBasis.wl"}]];
Export[FileNameJoin[{out,"CandidateReport.json"}],report,"RawJSON"];Print[report];
If[!TrueQ[spans],Return[Failure["ConstantCandidatesDoNotSpan",<|"Report"->report|>]]];

 <|"Report"->report,"Basis"->chosen,"PhysicalBasis"->candidatePhysical[[selected]],"PhysicalRows"->physicalRows,"ActualPhysicalBasis"->physicalRows[[actualRows]],"FullPoolHash"->reference["FullPoolHash"]|>];
