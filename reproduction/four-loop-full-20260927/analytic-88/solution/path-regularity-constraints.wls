$IterationLimit=Infinity;o=DirectoryName[$InputFileName];r=DirectoryName[DirectoryName[o]];
a=Get[FileNameJoin[{r,"dlog","Full88DLog.wl"}]];s=Get[FileNameJoin[{o,"ChenResidues.wl"}]];
rr[m_]:=Select[RowReduce[m],AnyTrue[#,UnequalTo[0]]&];rx=s["Rx"];v=rr[s["YBoundaryResidue"]];hist={Length[v]};
Do[vv=rr[Join[v,Sequence@@(v.#& /@rx)]];AppendTo[hist,Length[vv]];If[Length[vv]===Length[v],v=vv;Break[]];v=vv,{8}];
line=rr[Join[v,rx[[2]]]];ci=Select[Range[Length[a["Letters"]]],Together[a["Letters"][[#]]/.{x->1,y->1}]===0&];corner=rr[Flatten[a["ResidueMatrices"][[ci]],1]];
Put[<|"PathRegularityConstraints"->line,"YBoundaryInvariantConstraints"->v,"XInitialResidue"->rx[[2]],"CornerSeparateResidueConstraints"->corner,"CornerLetterIndices"->ci,"YConstraintRankHistory"->hist,"PathConstraintRank"->Length[line],"SeparateCornerConstraintRank"->Length[corner]|>,FileNameJoin[{o,"PathRegularityConstraints.wl"}]];
Print[<|"YClosureRanks"->hist,"PathRank"->Length[line],"CornerSeparateResidueRank"->Length[corner],"CornerLetters"->a["Letters"][[ci]]|>];Quit[];
