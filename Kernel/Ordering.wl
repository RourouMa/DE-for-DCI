legacySimpleKey[f_,g_G]:=Module[{a=List@@g,ps=parts[f,g],ext,boxScore=0},
 ext=Complement[Range[Length[f["Propagators"]]],f["LoopLoopIDs"]];
 Do[With[{v=a[[Select[ext,MemberQ[f["Supports"][[#]],First[block]]&]]]},
  If[Count[v,_?Positive]>1,boxScore+=Total[Max[Abs[#]-2,0]& /@ v]]],{block,Select[ps,Length[#]===1&]}];
 {Boole[Length[ps]>1],-Total[Abs[Pick[a[[f["LoopLoopIDs"]]],f["TopSector"][[f["LoopLoopIDs"]]],0]]],
  -boxScore,-Total[Abs[Take[a,Length[f["Propagators"]]]]],-Max[Abs[a]],a}];
(* Earlier columns are eliminated first; higher tier is preferred as a free representative. *)
$fourTierCache=<||>;
fourTier[f_,g_G]:=Module[{key={f["Hash"],g},value},If[KeyExistsQ[$fourTierCache,key],Return[$fourTierCache[key]]];
 value=2 Boole[Length[parts[f,g]]>1]+Boole[FiniteIntegralQ[f,g]];If[!MemberQ[{0,1,2,3},value],Return[fail["InvalidOrderingTier","Ordering tier must be an integer."]]];
 AssociateTo[$fourTierCache,key->value];value];
(* ordering01's structural and reference-shape key, adapted to family slot metadata.
   The inherited local column order is the final stable tie breaker. *)
Get[FileNameJoin[{DirectoryName[$packageFile],"Ordering01Symmetry.wl"}]];
$ordering01ReferencePath=FileNameJoin[{DirectoryName[$packageFile],"Ordering01Reference.wl"}];
$ordering01Reference=Get[$ordering01ReferencePath];
$ordering01Raw=Union[Cases[$ordering01Reference,g:(_G|_G1|_G2|_G3)/;MemberQ[{5,11,18},Length[List@@g]]:>(G@@List@@g),Infinity]];
$ordering01ByLoop=GroupBy[$ordering01Raw,crLoopCount[Length[List@@#]]&];
$ordering01Sets=Association@Table[With[{orbit=Union[Flatten[crOrbit[List@@#]& /@ Lookup[$ordering01ByLoop,Key[l],{}],1]]},l->AssociationThread[G@@@orbit,ConstantArray[True,Length[orbit]]]],{l,3}];
ordering01FactorVector[f_,a_,block_]:=Module[{ids,pairs},
 ids=Flatten[Table[First[FirstPosition[f["Propagators"],SP[x,f["Loops"][[i]]]]],{i,block},{x,f["External"]}]];
 pairs=(f["Loops"][[block[[#]]]]& /@ edges[Length[block]]);
 ids=Join[ids,(First[FirstPosition[f["Propagators"],SP@@#]]& /@ pairs),Length[f["Propagators"]]+block];a[[ids]]];
ordering01InnerKey[f_,g_G]:=Module[{a=List@@g,ps=parts[f,g],off,ext,box=0,score=0,v,fac},
 fac=Length[ps]>1;off=Pick[f["LoopLoopIDs"],f["TopSector"][[f["LoopLoopIDs"]]],0];
 ext=Complement[Range[Length[f["Propagators"]]],f["LoopLoopIDs"]];
 If[fac,
  Do[v=a[[Select[ext,f["Supports"][[#]]==={First[block]}&]]];
   box+=If[Min[v]>=0 && Count[v,_?Positive]===1,0,-Total[Select[v,Negative]]+Max[Max[v]-2,0]],{block,Select[ps,Length[#]===1&]}];
  score=Total[If[KeyExistsQ[$ordering01Sets,Length[#]] && KeyExistsQ[$ordering01Sets[Length[#]],G@@ordering01FactorVector[f,a,#]],Length[#],0]& /@ ps]];
 {Boole[fac],-Total[Max[#,0]& /@ a[[off]]],-Total[Abs[a[[off]]]],-box,score,
  -Boole[Max[a[[ext]]]>=4 || Min[Take[a,Length[f["Propagators"]]]]<=-2],legacySimpleKey[f,g]}];
$simpleKeyCache=<||>;
simpleKey[f_,g_G]:=Module[{key={f["Hash"],Lookup[f,"IntegralOrdering","TierReference"],g},value},
 If[KeyExistsQ[$simpleKeyCache,key],Return[$simpleKeyCache[key]]];
 value=Switch[Lookup[f,"IntegralOrdering","TierReference"],
 "TierReference",Prepend[ordering01InnerKey[f,g],fourTier[f,g]],
 "TierLadder",Join[{fourTier[f,g],Boole[originalDomainIntegralQ[f,g]]},legacySimpleKey[f,g]],
 "TierBlocks",Prepend[legacySimpleKey[f,g],fourTier[f,g]],
 "Reference",ordering01InnerKey[f,g],
 "LadderFirst",Prepend[legacySimpleKey[f,g],Boole[originalDomainIntegralQ[f,g]]],
 _,legacySimpleKey[f,g]];
 AssociateTo[$simpleKeyCache,key->value];value];
