(* User limits, 2026-09-27: selected finite representatives have external-loop
   denominator powers <=3 and loop-loop powers <=2. These are selection limits,
   not restrictions on the physical equations or their derivative targets. *)

representativePolePowers[f_Association,g_G]:=representativePolePowers[f,g]=If[validIntegral[f,g],
 With[{a=List@@g,ll=f["LoopLoopIDs"],ext=Complement[Range[Length[f["Propagators"]]],f["LoopLoopIDs"]]},
 {Max[0,Sequence@@a[[ext]]],Max[0,Sequence@@a[[ll]]]}],{Infinity,Infinity}];
representativePoleExcess[f_Association,g_G]:=Max[0,Sequence@@(representativePolePowers[f,g]-{3,2})];
representativePoleLimitsQ[f_Association,e_]:=AllTrue[support[e],representativePoleExcess[f,#]===0&];
representativePoleAudit[f_Association,basis_List]:=Module[{atoms=support[basis],powers,bad},
 powers=representativePolePowers[f,#]& /@ atoms;bad=Select[atoms,representativePoleExcess[f,#]>0&];
 <|"ExternalLoopPowerLimit"->3,"LoopLoopPowerLimit"->2,"HardSelectionLimits"->True,
 "MaximumExternalLoopPower"->Max[0,Sequence@@(First /@ powers)],
 "MaximumLoopLoopPower"->Max[0,Sequence@@(Last /@ powers)],
 "PropagatorPowerLimitsSatisfied"->(bad==={}),"PowerLimitViolatingAtomCount"->Length[bad]|>];

connectedPolePower[f_Association,g_G]:=connectedPolePower[f,g]=If[
 validIntegral[f,g]&&Length[parts[f,g]]===1,
 Max[0,Sequence@@Take[List@@g,Length[f["Propagators"]]]],0];
connectedPoleScore[f_Association,e_]:=Module[{excess=representativePoleExcess[f,#]& /@ support[e]},
 {Boole[AnyTrue[excess,#>0&]],Max[0,Sequence@@excess],Total[excess],Count[excess,_?Positive]}];
finiteRepresentativeCost[f_,e_]:=Module[{ps=IntegralComplexity[f,#]& /@ support[e]},
 Join[connectedPoleScore[f,e],{Length[ps],Max[0,Sequence@@Lookup[ps,"JointExcess"]],
 Max[0,Sequence@@Lookup[ps,"MaxDenominatorPower"]],Total[Lookup[ps,"NumeratorDegree"]],Total[Lookup[ps,"Dots"]],e}]];
connectedPoleAudit[f_Association,basis_List]:=Module[{atoms=Union@@(support /@ basis),bad,counts},
 bad=Select[atoms,connectedPolePower[f,#]>=4&];
 counts=connectedPolePower[f,#]& /@ atoms;
 Join[representativePoleAudit[f,basis],<|"Preference"->"ExternalLoopAtMostThreeLoopLoopAtMostTwo","SoftPreference"->False,
 "ConnectedHighPowerAtomCount"->Length[bad],"MaximumConnectedPropagatorPower"->Max[0,Sequence@@counts],
 "BasisElementsContainingHighPowerConnectedAtoms"->Count[connectedPoleScore[f,#][[1]]& /@ basis,1],
  "HighPowerConnectedAtoms"->bad,"AllAlternativeRepresentativesExhausted"->False|>]];
(* A low-pole preference must not discard an already available exact-span
   constant cover. Equal pole scores alone are no reason to change a basis. *)
preferCertifiedFiniteCoverQ[f_Association,current_Association,candidate_Association,rank_Integer]:=Module[
 {currentConstant,candidateConstant,oldScore,newScore},
 If[!representativePoleLimitsQ[f,candidate["Basis"]],Return[False]];
 If[Length[candidate["Basis"]]=!=rank,Return[False]];
 If[Length[current["Basis"]]>rank,Return[True]];
 currentConstant=AllTrue[current["Basis"],constantCombinationQ];
 candidateConstant=AllTrue[candidate["Basis"],constantCombinationQ];
 If[currentConstant&&!candidateConstant,Return[False]];
 If[!currentConstant&&candidateConstant,Return[True]];
 oldScore=connectedPoleScore[f,current["Basis"]];newScore=connectedPoleScore[f,candidate["Basis"]];
 newScore=!=oldScore&&OrderedQ[{newScore,oldScore}]];
