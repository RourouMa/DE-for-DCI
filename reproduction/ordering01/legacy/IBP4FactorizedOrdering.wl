(* Earlier FiniteFlow columns are eliminated first. Optional refinements keep
   the previous order as their final tie-breaker; lower-loop variables stay last. *)
f4Edges={{1,2},{2,3},{3,4},{1,3},{1,4},{2,4}};
f4FactorMasks=Table[Length[ConnectedComponents[Graph[Range[4],
 UndirectedEdge@@@Pick[f4Edges,Reverse[IntegerDigits[mask,2,6]],1]]]]>1,{mask,0,63}];
f4Mask[id_List]:=Unitize[id[[17;;22]]].{1,2,4,8,16,32};
f4FactorizedQ[g_G]:=f4FactorMasks[[1+f4Mask[List@@g]]];
f4IsolatedVertices=Table[Complement[Range[4],Union[Flatten[Pick[f4Edges,
 Reverse[IntegerDigits[mask,2,6]],1]]]],{mask,0,63}];
f4BoxComplexity[id_List]:=Total[Function[j,With[{v=id[[4j-3;;4j]]},
 If[Min[v]>=0 && Count[v,_?Positive]===1,0,
  -Total[Select[v,Negative]]+Max[Max[v]-2,0]]]] /@ f4IsolatedVertices[[1+f4Mask[id]]]];
f4FactorizedOrder[ordered_List]:=Module[{g4,g3,flags,connected,factorized,preferZero,moderate,reducedBoxes,indices,answer},
 g4=Select[ordered,MatchQ[#,_G]&];g3=Select[ordered,MatchQ[#,_G3]&];
 If[Length[g4]+Length[g3]!=Length[ordered],Print["Unknown integral head in ordering"];Abort[]];
 flags=f4FactorizedQ /@ g4;
 connected=Pick[g4,flags,False];factorized=Pick[g4,flags,True];
 preferZero=TrueQ[IBP4PreferZeroLoopISP] || Environment["IBP4_PREFER_ZERO_LOOP_ISP"]==="1";
 moderate=TrueQ[IBP4PreferModeratePowers] || Environment["IBP4_PREFER_MODERATE_POWERS"]==="1";
 reducedBoxes=TrueQ[IBP4PreferReducedIsolatedBoxes] || Environment["IBP4_PREFER_REDUCED_BOX_FACTORS"]==="1";
 indices=If[preferZero || moderate || reducedBoxes,SortBy[Range[Length[g4]],Function[k,
   {Boole[flags[[k]]],If[preferZero,-Total[Max[#,0]& /@ (List@@g4[[k]])[[20;;22]]],0],
    If[preferZero,-Total[Abs[(List@@g4[[k]])[[20;;22]]]],0],
    If[reducedBoxes && flags[[k]],-f4BoxComplexity[List@@g4[[k]]],0],
    If[moderate,-Boole[Max[(List@@g4[[k]])[[1;;16]]]>=4 || Min[(List@@g4[[k]])[[1;;22]]]<=-2],0],k}]],{}];
 answer=If[preferZero || moderate || reducedBoxes,Join[g4[[indices]],g3],Join[connected,factorized,g3]];
 <|"Order"->answer,"ConnectedG4"->Length[connected],
  "FactorizedG4"->Length[factorized],"G3"->Length[g3],
  "OriginalWithinClassOrderingPreserved"->!(preferZero || moderate || reducedBoxes),
  "OriginalTieOrderPreserved"->True,"PreferZeroNonAdjacentLoopISP"->preferZero,
  "PreferModerateExternalAndNumeratorPowers"->moderate,
  "PreferReducedIsolatedBoxFactors"->reducedBoxes,
  "Policy"->("Prefer factorized free representatives"<>
    If[preferZero,", avoid positive nonadjacent loop denominators, then smaller absolute loop ISP degree",""]<>
    If[reducedBoxes,", then simpler isolated box factors; pure tadpole powers exempt from this score",""]<>
    If[moderate,", then prefer external powers at most three and numerator powers at most one",""]<>
    ", then original order; G3 last"),
  "GraphCriterion"->"All six nonzero loop-loop powers connect blocks, including numerators"|>];
