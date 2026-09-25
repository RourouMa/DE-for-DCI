(* Reporting is a contract: raw support, finite cover, rank and closure are distinct. *)
constantCombinationQ[e_]:=AllTrue[Flatten[coeff[{e},support[e]]],MatchQ[Together[#],_Integer|_Rational]&];
variableDecisionQ[d_]:=AssociationQ[d] && AllTrue[
 {"Reason","ConstantSearchSummary","RelationAudit","AlternativesCompared"},
 StringQ[Lookup[d,#,None]] && StringLength[StringTrim[Lookup[d,#,""]]]>0&];
finiteBasisContract[f_,finite_,normalFormRows_:Automatic,policy_:"StrictOrdering"]:=Module[{basis,single,combinations,raw,extra,missing,effective,checked},
 If[FailureQ[finite],Return[finite]];
 If[policy==="FiniteSupportThenSpan",
  If[!ListQ[normalFormRows],Return[fail["FiniteBasisRows","FiniteSupportThenSpan requires the full normal-form rows."]]];
  effective=effectiveFiniteBasisPolicy[f,normalFormRows,policy];
  checked=finiteBasisContract[f,finite,normalFormRows,effective];
  Return[If[FailureQ[checked],checked,Join[checked,<|"FiniteBasisPolicy"->policy,"EffectiveFiniteBasisPolicy"->effective|>]]]];
 If[!AssociationQ[finite]||!TrueQ[Lookup[finite,"ExactCoverage",False]],Return[fail["UnverifiedFiniteCover","No next-round basis without a complete coverage certificate."]]];
 basis=Lookup[finite,"Basis",{}];single=Lookup[finite,"SingleFinite",{}];combinations=Lookup[finite,"Combinations",{}];
 If[Sort[Join[single,combinations]]=!=Sort[basis]||!AllTrue[single,MatchQ[#,_G]&],
  Return[fail["FiniteBasisCountMismatch","Basis must contain exactly all declared singles and combinations; no hidden elements."]]];
 If[!MemberQ[{"StrictOrdering","PreserveActualSpan"},policy],Return[fail["FiniteBasisPolicy","Unknown finite-cover policy."]]];
 If[policy==="PreserveActualSpan"&&!(TrueQ[Lookup[finite,"SpanPreserving",False]]&&TrueQ[Lookup[finite,"CoverageViaVerifiedReduction",False]]&&Lookup[finite,"ActualRationalRank",Missing[]]===Length[basis]),Return[fail["UnverifiedActualSpan","Adaptive coverage requires verified membership, coverage and rank."]]];
 If[ListQ[normalFormRows]&&policy==="StrictOrdering",
  raw=support[normalFormRows];extra=Complement[support[basis],raw];
  If[extra=!={},Return[fail["OrderingPreferenceViolation","Finite coverage must use the surviving normal-form atoms. Do not reintroduce eliminated queries as a new preferred basis.",<|"ReintroducedAtoms"->extra|>]]];
  missing=Complement[Select[raw,FiniteIntegralQ[f,#]&],single];
  If[missing=!={},Return[fail["PreferredFiniteSinglesOmitted","Retain individually finite normal-form representatives; actual DE row-rank compression is not an ordering-preserving basis selection.",<|"MissingSingleFinite"->missing|>]]]];
 If[!AllTrue[combinations,constantCombinationQ] && !variableDecisionQ[Lookup[finite,"VariableCoefficientDecision",None]],
  Return[fail["VariableCoefficientDecisionRequired","Constant coefficients are preferred, not mandatory. Record the constant search, relation audit, alternatives and reason before accepting a variable-coefficient basis."]]];
 If[!AllTrue[basis,FiniteIntegralQ[f,#]&],Return[fail["UncertifiedFiniteBasis","Each complete basis expression must pass the finite criterion."]]];
 If[ListQ[normalFormRows],Join[finite,<|"FiniteBasisPolicy"->policy,"OrderingPreferencePreserved"->(policy==="StrictOrdering"),"BasisSelectionScope"->If[policy==="StrictOrdering","Surviving normal-form atoms and their finite combinations","Verified finite representatives inside the actual rational span"]|>],finite]];
reportContext[s_,round_]:=<|"ReportSchemaVersion"->1,"Strategy"->Lookup[s["Family"],"IntegralOrdering",Missing["NotRecorded"]],
 "FiniteBasisPolicy"->Lookup[s["Options"],"FiniteBasisPolicy","StrictOrdering"],"Epoch"->s["Epoch"],"ReplayNumber"->s["Epoch"],"Round"->round,
 "EquationCount"->Length[s["Equations"]],"EquationPoolHash"->Hash[s["Equations"],"SHA256"]|>;
rawSupportReport[f_,expressions_]:=Module[{gs=support[expressions],n},n=Count[FiniteIntegralQ[f,#]& /@ gs,True];
 <|"RawSupport"->Length[gs],"RawSingleFinite"->n,"RawNotIndividuallyFinite"->Length[gs]-n,
 "RawSupportIsMasterCount"->False,"BoundarySources"->Length[sources[expressions]]|>];
finiteRoundReport[s_,round_,basis_,der_,fullInput_,fullDE_,reduction_,finite_,inputRank_,unclosedRows_]:=Module[
 {f=s["Family"],closed=unclosedRows==={},rank,definitions,complexity,nconstant,dir=s["Options"]["OutputDirectory"]},
 rank=Lookup[finite,"ActualRationalRank",If[closed,inputRank,Missing["NotComputed"]]];
 definitions=finite["Combinations"];
 nconstant=Count[constantCombinationQ /@ definitions,True];
 complexity=Table[With[{c=Together /@ First[coeff[{e},support[e]]],constant=constantCombinationQ[e]},
  <|"TermCount"->Length[c],"ConstantCoefficients"->constant,"CoefficientLeafCount"->LeafCount[c],
    "CoefficientAbsSum"->If[constant,Total[Abs[c]],Missing["VariableCoefficients"]],
    "MaxAbsCoefficient"->If[constant,Max[Abs[c]],Missing["VariableCoefficients"]]|>],{e,definitions}];
 Join[reportContext[s,round],rawSupportReport[f,{fullInput,fullDE}],
 <|"Event"->"RoundVerified","InputCount"->Length[basis],"DERows"->Length[fullDE],"Targets"->Length[der["Targets"]],
 "SingleFinite"->Length[finite["SingleFinite"]],"Combinations"->Length[definitions],"OutputCount"->Length[finite["Basis"]],
 "CountsIncludeAllCombinations"->True,"ConstantCombinations"->nconstant,"VariableCombinations"->Length[definitions]-nconstant,
 "ConstantCombinationCoefficients"->(nconstant===Length[definitions]),"CombinationComplexity"->complexity,"IntegralComplexityAudit"->Lookup[s,"ComplexityAudit",Missing["NotRecorded"]],
 "VariableCoefficientDecision"->Lookup[finite,"VariableCoefficientDecision",Missing["NotNeeded"]],
 "InputRationalRank"->inputRank,"ActualRationalRank"->rank,"ActualRankVerified"->IntegerQ[rank],
 "OutputCountIsMasterCount"->False,"ExactCoverage"->True,"ClosedOnSameInput"->closed,
 "EffectiveFiniteBasisPolicy"->Lookup[finite,"EffectiveFiniteBasisPolicy",Lookup[finite,"FiniteBasisPolicy","StrictOrdering"]],
 "UnclosedDERowCount"->Length[unclosedRows],"UnclosedDERows"->unclosedRows,
 "FullClosureVerified"->False,"FlatnessVerified"->Missing["NotCheckedAtRoundStage"],
 "FactorizedSingleFinite"->Count[(Length[parts[f,#]]>1& /@ finite["SingleFinite"]),True],
 "SelfReducedQueries"->Length[reduction["SelfReducedTargets"]],"UnseenQueries"->Length[reduction["UnseenTargets"]],
 "ReductionVerificationMode"->Lookup[reduction,"VerificationMode",Missing["NotRecorded"]],
 "VerificationPoints"->Lookup[reduction,"NumericalVerificationPoints",Missing["NotRecorded"]],
 "NewRelations"->0,"NextAction"->If[closed,"Assemble and verify retained sources and full system","Differentiate complete certified finite expressions, including their coefficients"],
 "FiniteBasisArtifact"->If[StringQ[dir],FileNameJoin[{dir,"epoch"<>ToString[s["Epoch"]],"round"<>ToString[round],"FiniteBasis.wl"}],Missing["NoOutputDirectory"]]|>]];
