(* Original-family preference is an optimization AFTER certified DE closure.
   It is never evidence for closure and cannot discard necessary outside integrals. *)
preferFamilyAfterClosure[state_Association]:=Module[
 {s=state,f=state["Family"],basis=state["Basis"],rules,old,gs,m,p,n,pool,coordinateInverse,
  candidates={},vectors={},image,v,residual,chosen={},transform={},inv,newMatrices,
  curvature,oldCount,newCount,audit,result},
 If[!TrueQ[Lookup[s,"Closed",False]] || !TrueQ[Lookup[s,"FlatnessVerified",False]],
  Return[Join[s,<|"FamilyPreferenceAudit"-><|"Applied"->False,"Reason"->"Full DE closure and flatness are prerequisites"|>|>]]];
 n=Length[basis];rules=Dispatch[s["LastReduction"]["Rules"]];
 old=canonicalLinear /@ ((canonExpr[f,#]& /@ basis)/.rules);
 gs=Join[support[old],sources[old]];m=coeff[old,gs];p=pivots[rr[m]];
 If[n===0 || Length[p]=!=n,Return[Join[s,<|"FamilyPreferenceAudit"-><|"Applied"->False,"Reason"->"Empty or dependent closed basis"|>|>]]];
 coordinateInverse=linearInverse[m[[All,p]]];
 (* Only already reduced candidates are eligible. No new equations or pole assumptions. *)
 pool=DeleteDuplicates[Join[basis,Select[s["OriginalInputs"],originalDomainExpressionQ[f,#]&],
   Select[support[s["LastReduction"]["Rules"]],originalDomainIntegralQ[f,#]&]]];
 pool=SortBy[pool,{Boole[!originalDomainExpressionQ[f,#]]&,Length[support[#]]&,LeafCount,Identity}];
 Do[
  If[!TrueQ[FiniteIntegralQ[f,candidate]],Continue[]];
  image=canonExpr[f,candidate];If[FailureQ[image],Continue[]];image=canonicalLinear[image/.rules];
  If[FailureQ[image],Continue[]];
  v=Map[Together,First[coeff[{image},gs]][[p]].coordinateInverse];
  residual=canonicalLinear[image-v.old];
  If[!TrueQ[residual===0],Continue[]];
  AppendTo[candidates,candidate];AppendTo[vectors,v],{candidate,pool}];
 Do[If[Length[rr[Append[transform,vectors[[k]]]]]>Length[transform],
   AppendTo[chosen,candidates[[k]]];AppendTo[transform,vectors[[k]]]],{k,Length[candidates]}];
 If[Length[chosen]=!=n,Return[Join[s,<|"FamilyPreferenceAudit"-><|"Applied"->False,"Reason"->"No invertible certified replacement"|>|>]]];
 inv=Map[Together,linearInverse[transform],{2}];
 newMatrices=Association@Table[z->Map[Together,(D[transform,z]+transform.s["Matrices"][z]).inv,{2}],{z,f["Variables"]}];
 curvature=Table[With[{a=f["Variables"][[i]],b=f["Variables"][[j]]},
  Map[Together,D[newMatrices[a],b]-D[newMatrices[b],a]+newMatrices[a].newMatrices[b]-newMatrices[b].newMatrices[a],{2}]],
  {i,Length[f["Variables"]]},{j,i+1,Length[f["Variables"]]}];
 oldCount=Count[originalDomainExpressionQ[f,#]& /@ basis,True];
 newCount=Count[originalDomainExpressionQ[f,#]& /@ chosen,True];
 If[newCount<oldCount || !And@@(zero /@ Flatten[curvature]),
  Return[Join[s,<|"FamilyPreferenceAudit"-><|"Applied"->False,"Reason"->"Replacement failed preference or flatness checks; closed basis retained"|>|>]]];
 audit=<|"Applied"->True,"Priority"->{"CertifiedFiniteness","VerifiedFullDEClosure","OriginalFamilyPreference"},
  "CandidateCount"->Length[pool],"CertifiedInSpanCandidates"->Length[candidates],
  "OriginalFamilyCountBefore"->oldCount,"OriginalFamilyCountAfter"->newCount,
  "BasisCount"->n,"ExactChangeOfBasis"->True,"BoundaryEqualityPreserved"->True,
  "FlatnessVerified"->True,"GlobalPreferenceOptimumClaimed"->False,
  "Scope"->"Maximize original-family elements among available certified in-span candidates; retain outside integrals when required"|>;
 result=Join[s,<|"Basis"->chosen,"Matrices"->newMatrices,"BasisBeforeFamilyPreference"->basis,
   "FamilyPreferenceTransform"->transform,"FamilyPreferenceInverse"->inv,"FamilyPreferenceAudit"->audit|>];
 If[KeyExistsQ[s,"InputReconstructionMatrix"],result["InputReconstructionMatrix"]=Map[Together,s["InputReconstructionMatrix"].inv,{2}]];
 (* Full closure implies these source rows are zero; preserve their new basis dimension. *)
 result["BoundaryRows"]=ConstantArray[0,n Length[f["Variables"]]];result];
