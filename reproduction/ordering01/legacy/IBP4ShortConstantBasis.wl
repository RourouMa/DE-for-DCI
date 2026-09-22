(* All candidate directions must lie in the already extracted finite span. *)
Clear[ShortConstantFiniteBasis];
ShortConstantFiniteBasis[original_] := Module[
 {b=original,n,r,p,q,groups,reps,duos,sumGroups,candidates,unit,normalize,score,
  pool,rr={},pivots={},selected={},v,w,k,pr,changed=True,before,best,trial,
  ratios,moves={},idx,shortRank,derived,den,fingerprints,triples,sixGroups,sixCandidates={},prime},
 n=Length[First[b]];r=itRR[b];p=itPiv[r];
 normalize[row_]:=Module[{a=row,d,g},If[!AnyTrue[a,#!=0&],Return[a]];
  d=LCM@@(Denominator /@ a);a=d a;g=GCD@@Abs[a];Sign[First[Select[a,#!=0&]]] a/g];
 score[row_]:={Count[row,Except[0]],Total[Abs[row]],Max[Abs[row]]};
 q=IdentityMatrix[n]-IdentityMatrix[n][[All,p]].r;
 groups=GatherBy[Range[n],q[[#]]&];reps=First /@ groups;
 q=q[[All,Complement[Range[n],p]]];unit[i_]:=UnitVector[n,i];
 duos=Join[({#,#}& /@ reps),Subsets[reps,{2}]];
 sumGroups=Select[GatherBy[duos,Hash[Total[q[[#]]],"SHA256"]&],Length[#]>1&];
 candidates=DeleteDuplicates[Flatten[Table[Table[
   If[Total[q[[First[g]]]]=!=Total[q[[d]]],Return[$Failed]];
   normalize[Total[unit /@ First[g]]-Total[unit /@ d]],{d,Rest[g]}],{g,sumGroups}],1]];
 If[Max[Count[#,Except[0]]& /@ b]>6,
  den=LCM@@(Denominator /@ Flatten[q]);prime=2^61-1;
  fingerprints=BlockRandom[SeedRandom[513];Mod[(den q).RandomInteger[{1,prime-1},Length[First[q]]],prime]];
  triples=Subsets[reps,{3}];
  sixGroups=Select[GatherBy[triples,Mod[Total[fingerprints[[#]]],prime]&],Length[#]>1&];
  sixCandidates=Reap[Do[Do[If[Total[q[[First[g]]]]===Total[q[[d]]],
    Sow[normalize[Total[unit /@ First[g]]-Total[unit /@ d]]]],{d,Rest[g]}],{g,sixGroups}]][[2]];
  sixCandidates=If[sixCandidates==={},{},DeleteDuplicates[Flatten[sixCandidates,1]]]];
 pool=DeleteDuplicates[Join[b,candidates,sixCandidates]];
 pool=SortBy[pool,{score,Identity}];
 (* Test independence with triangular working rows, but retain each short
    original vector as the actual finite block. *)
 Do[w=v;Do[w=w-w[[pivots[[k]]]] rr[[k]],{k,Length[rr]}];
  If[AnyTrue[w,#!=0&],pr=First[Select[Range[n],w[[#]]!=0&]];
   AppendTo[rr,w/w[[pr]]];AppendTo[pivots,pr];AppendTo[selected,v]],{v,pool}];
 shortRank=Count[selected,row_/;Count[row,Except[0]]<=4];b=selected;
 While[changed,
  changed=False;
  Do[
   before=b[[i]];best=before;
   Do[If[j!=i,
    idx=Select[Range[n],b[[i,#]]!=0 && b[[j,#]]!=0&];
    ratios=DeleteDuplicates[b[[i,idx]]/b[[j,idx]]];
    Do[trial=normalize[b[[i]]-t b[[j]]];
     If[OrderedQ[{score[trial],score[best]}] && score[trial]=!=score[best],best=trial],{t,ratios}]],{j,Length[b]}];
   If[best=!=before,AppendTo[moves,<|"Block"->i,"Before"->before,"After"->best|>];b[[i]]=best;changed=True],
   {i,Reverse[Range[Length[b]]]}]];
 b=SortBy[b,{score,Identity}];
 derived=b[[All,p]].Inverse[original[[All,p]]];
 If[Length[b]=!=Length[original] || b=!=derived.original || Length[itRR[b]]=!=Length[b],Return[$Failed]];
 <|"Rows"->b,"Transformation"->derived,"AdditionalFourTermCandidates"->Length[candidates],
  "AdditionalSixTermCandidates"->Length[sixCandidates],
  "ShortCandidateRank"->shortRank,"SparsifyingMoves"->moves,"SupportHistogram"->Counts[Count[#,Except[0]]& /@ b]|>
];
