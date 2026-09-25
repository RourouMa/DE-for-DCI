(* Explicit adaptive policy. This does not redefine the ordering's free columns. *)
spanFFRowSpace[m_List]:=Module[{cols,rules,r,p},
 If[m==={}||First[m]==={}||AllTrue[Flatten[m],zero],Return[{}]];
 cols=G /@ Range[Length[First[m]]];
 rules=FiniteFlow`FFSparseSolve[#==0& /@ DeleteCases[m.cols,0],cols];
 If[!ListQ[rules],Return[fail["SpanRowSpace","FiniteFlow row-space reconstruction failed."]]];
 r=coeff[(First /@ rules)-(Last /@ rules),cols];r=SortBy[r,First[pivots[{#}]]&];p=pivots[r];
 If[r[[All,p]]=!=IdentityMatrix[Length[r]]||!AllTrue[Flatten[m-m[[All,p]].r],zero],Return[fail["SpanRowSpaceCertificate","Exact rational row-space coverage failed."]]];r];
finiteRepresentativeCost[f_,e_]:=Module[{ps=IntegralComplexity[f,#]& /@ support[e]},
 {Length[ps],Max[Lookup[ps,"JointExcess"]],Max[Lookup[ps,"MaxDenominatorPower"]],Total[Lookup[ps,"NumeratorDegree"]],Total[Lookup[ps,"Dots"]],e}];
(* Whole physical derivatives contain useful constant combinations which their
   separate atoms do not reveal. Membership is still checked after reduction. *)
physicalConstantCandidates[f_,queries_List]:=Module[{whole,atoms,c,blocks},
 whole=Select[queries,Length[support[#]]>1&];If[whole==={},Return[{}]];
 atoms=support[whole];c=Map[Together,coeff[whole,atoms],{2}];
 blocks=constantAtoms[c,f["Variables"]];If[blocks===$Failed,Return[{}]];
 blocks=DeleteDuplicates[primitive /@ blocks];
 Select[DeleteCases[canonicalLinear /@ (#.atoms& /@ blocks),0],FiniteIntegralQ[f,#]&]];
BuildSpanPreservingFiniteBasis[f_Association,rows_List,queries_List,reduction_Association]:=Module[
 {raw=support[rows],known,cs,images,actual,c,r,p,eligible,ec,ind,basis,bi,atoms,av,bv,eq,rules,wi,w,res,rank,baseline},
 If[!MemberQ[$Packages,"FiniteFlow`"],Return[fail["FiniteFlowRequired","PreserveActualSpan requires FiniteFlow; initialize it before the campaign."]]];
 known=Association[Lookup[reduction,"Rules",{}]];actual=rows/._BoundaryIntegral->0;c=coeff[actual,raw];r=spanFFRowSpace[c];If[FailureQ[r],Return[r]];rank=Length[r];
 If[rank===0,Return[<|"Basis"->{},"SingleFinite"->{},"Combinations"->{},"Weights"->ConstantArray[{},Length[rows]],"ReducedBasis"->{},"BoundaryRows"->rows,"ExactCoverage"->True,"SpanPreserving"->True,"ActualRationalRank"->0,"CoverageViaVerifiedReduction"->True,"FiniteBasisPolicy"->"PreserveActualSpan"|>]];
 p=pivots[r];baseline=BuildFiniteBasis[f,rows];
 cs=Union[raw,support[queries],Select[queries,Length[support[#]]>1&&constantCombinationQ[#]&],physicalConstantCandidates[f,queries],If[AssociationQ[baseline],baseline["Basis"],{}]];
 cs=Select[cs,FiniteIntegralQ[f,#]&&AllTrue[support[canonExpr[f,#]],KeyExistsQ[known,#]||MemberQ[raw,#]&]&];
 cs=SortBy[cs,finiteRepresentativeCost[f,#]&];
 images=closureLinear /@ ((canonExpr[f,#]& /@ cs)/.Dispatch[Normal[known]]);
 eligible=Select[Range[Length[cs]],Complement[support[images[[#]]],raw]==={}&&With[{v=First[coeff[{images[[#]]}/._BoundaryIntegral->0,raw]]},AllTrue[v-v[[p]].r,zero]]&];
 If[eligible==={},Return[fail["SpanFiniteCoverIncomplete","No certified finite candidate lies in the actual span.",<|"ActualRationalRank"->rank|>]]];
 ec=coeff[images[[eligible]]/._BoundaryIntegral->0,raw];ind=spanFFRowSpace[Transpose[ec]];If[FailureQ[ind],Return[ind]];ind=pivots[ind];
 If[Length[ind]=!=rank,Return[fail["SpanFiniteCoverIncomplete","Finite candidates do not cover the actual span; inspect constant combinations and missing relations.",<|"ActualRationalRank"->rank,"FiniteCandidateRank"->Length[ind],"MissingDirections"->rank-Length[ind]|>]]];
 basis=cs[[eligible[[ind]]]];bi=images[[eligible[[ind]]]];atoms=support[{rows,bi}];av=G /@ (-Range[Length[rows]]);bv=G /@ (-100000-Range[Length[basis]]);
 eq=Join[(bi/._BoundaryIntegral->0)-bv,(rows/._BoundaryIntegral->0)-av];
 rules=FiniteFlow`FFSparseSolve[#==0& /@ eq,Join[atoms,av,bv],"NeededVars"->av];If[!ListQ[rules],Return[fail["SpanCoordinates","FiniteFlow coordinate reconstruction failed."]]];
 wi=av/.Dispatch[rules];If[Complement[support[wi],bv]=!={},Return[fail["SpanCoordinates","Uncovered directions remain in the exact coordinate reconstruction."]]];
 w=coeff[wi,bv];res=closureLinear /@ (rows-w.bi);If[!AllTrue[res/._BoundaryIntegral->0,zero],Return[fail["SpanCoverage","Exact coverage residuals are nonzero."]]];
 <|"Basis"->basis,"SingleFinite"->Select[basis,MatchQ[#,_G]&],"Combinations"->Select[basis,!MatchQ[#,_G]&],"Weights"->w,"ReducedBasis"->bi,"BoundaryRows"->res,"ExactCoverage"->True,"ActualRationalRank"->rank,"SpanPreserving"->True,"CoverageViaVerifiedReduction"->True,"FiniteBasisPolicy"->"PreserveActualSpan","OrderingPreferencePreserved"->False,"NoKinematicsInCombinations"->True,"ConstantCombinationRank"->Count[basis,Except[_G]],"GlobalSparsityOptimumClaimed"->False|>];
effectiveFiniteBasisPolicy[f_,rows_,policy_]:=If[policy==="FiniteSupportThenSpan",
 If[AllTrue[support[rows],FiniteIntegralQ[f,#]&],"StrictOrdering","PreserveActualSpan"],policy];
$lastFiniteCover=<||>;
campaignFiniteCover[f_,rows_,queries_,reduction_,policy_]:=Module[{key,result},
 If[effectiveFiniteBasisPolicy[f,rows,policy]==="StrictOrdering"&&AllTrue[support[rows],FiniteIntegralQ[f,#]&],
  result=BuildFiniteBasis[f,rows];Return[If[AssociationQ[result],Join[result,<|"FiniteCoverReused"->False|>],result]]];
 key=Hash[{f["Hash"],$implementationHash,rows,queries,Lookup[reduction,"Rules",{}],policy,TrueQ[$deferBoundaryCoefficientSimplification]},"SHA256"];
 If[Lookup[$lastFiniteCover,"Key",None]===key,
  result=$lastFiniteCover["Result"];Return[If[AssociationQ[result],Join[result,<|"FiniteCoverReused"->True|>],result]]];
 result=If[effectiveFiniteBasisPolicy[f,rows,policy]==="PreserveActualSpan",BuildSpanPreservingFiniteBasis[f,rows,queries,reduction],BuildFiniteBasis[f,rows]];
 $lastFiniteCover=<|"Key"->key,"Result"->result|>;
 If[AssociationQ[result],Join[result,<|"FiniteCoverReused"->False|>],result]];
