(* Cache the same four-loop operator action with an inert spectator factored
   out. Restore all 26 indices before the existing G3/delta processing. *)
factorIBPCache=<||>;factorCacheHits=0;factorCacheMisses=0;
factorEdges=Join[AdjacentLoopEdges,NonAdjacentLoopEdges];
factorUV=Transpose[UVRegionAssociation /@ LoopSubsetList];
factorIR=Transpose[IRRegionAssociation /@ LoopSubsetList];
factorDimensions=4 (Length /@ LoopSubsetList);
factorSeedDimensions[deg_]:=factorSeedDimensions[deg]=factorDimensions-(Total[deg[[#]]]& /@ LoopSubsetList);
factorSeedQ[a_,deg_]:=With[{dims=factorSeedDimensions[deg]},
 a.factorUV===dims && Max[a.factorIR-dims]<0];
factorFiniteQ[g_G]:=With[{a=Take[List@@g,22]},a.factorUV===factorDimensions && Max[a.factorIR-factorDimensions]<0];
factorOperatorLoops[op_]:=factorOperatorLoops[op]=Select[Range[4],!FreeQ[op,LoopVars[[#]]|pro[22+#]]&];
factorComponents[bits_]:=factorComponents[bits]=ConnectedComponents[
 Graph[Range[4],UndirectedEdge@@@Pick[factorEdges,bits]]];
Get[FileNameJoin[{DirectoryName[$InputFileName],"IBP4LaurentOperatorCache.wl"}]];
If[TrueQ[IBP4UseContactLaurent],Get[FileNameJoin[{DirectoryName[$InputFileName],"IBP4ContactLaurentCache.wl"}]]];
factorCachedIBP[op_,prop_,seed_G]:=Module[
 {a=List@@seed,opLoops,cs,active,inactive,inactiveEdges,ids,canonical,key,raw,restored,gs},
 If[TrueQ[IBP4UseContactLaurent],Return[contactLaurentIBP[op,prop,seed]]];
 If[Max[a[[17;;22]]]<=1,Return[factorLaurentIBP[op,prop,seed]]];
 opLoops=factorOperatorLoops[op];
 cs=factorComponents[(#!=0& /@ a[[17;;22]])];
 active=Union[Flatten[Select[cs,Intersection[#,opLoops]=!={}&]]];inactive=Complement[Range[4],active];
 If[inactive==={},Return[Operator2IBP[op,prop,seed]]];
 inactiveEdges=Select[Range[17,22],Complement[factorEdges[[#-16]],inactive]==={}&];
 If[inactiveEdges=!={} && Max[a[[inactiveEdges]]]>=2,Return[Operator2IBP[op,prop,seed]]];
 ids=Join[Flatten[Range[4#-3,4#]& /@ inactive],inactiveEdges,22+inactive];
 canonical=ReplacePart[a,Join[Thread[Flatten[Range[4#-3,4#]& /@ inactive]->1],Thread[inactiveEdges->0]]];
 key=FactorCacheKey[op,G@@canonical];
 If[KeyExistsQ[factorIBPCache,key],raw=factorIBPCache[key];factorCacheHits++,
  raw=spInt2PowerIDInt[Operator2IBPRat[op,prop,G@@canonical],prop]/.Kinematics;
  If[!FreeQ[raw,_sp],Return[Operator2IBP[op,prop,seed]]];
  AssociateTo[factorIBPCache,key->raw];factorCacheMisses++];
 gs=Union[Cases[{raw},_G,Infinity]];
 If[!And@@((List@@#)[[ids]]===canonical[[ids]]& /@ gs),Print["Spectator changed in cached operator action"];Return[$Failed]];
 restored=DropBadDeltaIntegrals[raw/.g_G:>(G@@ReplacePart[List@@g,Thread[ids->a[[ids]]]])];
 If[And@@(factorFiniteQ /@ Union[Cases[{restored},_G,Infinity]]) && FreeQ[restored,_sp],restored,False]
];
