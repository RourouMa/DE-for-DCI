(* Reproducible internal-collision certificate for two specific four-loop differences.
   This example does not relax the default validator or certify overlapping clusters. *)
root=DirectoryName[DirectoryName[$InputFileName]];
Get[FileNameJoin[{root,"Kernel","ConformalIBP.wl"}]];
Get[FileNameJoin[{root,"Examples","kinematics.wl"}]];
f=LadderFamily[4,kinematics,{x,y}];
g1=G[1,0,0,1,0,1,0,0,0,0,0,1,0,1,1,0,2,1,2,0,0,0,1,1,1,1];
g2=G[1,0,0,1,0,1,0,0,0,1,0,0,0,0,1,1,2,1,2,0,0,0,1,1,1,1];
ys=f["Loops"];pairs=Subsets[ys,{2}];forests=Select[Subsets[pairs,{2}],Intersection@@#==={}&];
orbit[e_]:=Module[{r,images},r=Total[Coefficient[Expand[e],#] ConformalIBP`Private`integrand[f,#]& /@ ConformalIBP`Private`support[e]];
 images=DeleteDuplicates[(r/.Thread[ys->#])& /@ Permutations[ys]];
 DeleteDuplicates[Flatten[Table[images/.Thread[f["External"]->f["External"][[ep]]],{ep,f["ExternalPermutations"]}],1]]];
collapse[r_,pair_]:=(r/.Last[pair]->First[pair])/.ConformalIBP`Private`scalarRules[f];
residue[images_,forest_]:=Together[Total[Fold[collapse,#,forest]& /@ (Cancel[Times@@((SP@@#)^2& /@ forest) #]& /@ images)]];
cases={{g1,g2},
 {G[1,0,0,1,0,1,0,0,0,0,0,1,-1,1,2,0,2,1,2,0,0,0,1,1,1,1],
  G[1,0,0,1,0,1,0,0,0,1,0,0,-1,0,2,1,2,1,2,0,0,0,1,1,1,1]}};
results=Table[g1=pairOfIntegrals[[1]];g2=pairOfIntegrals[[2]];
images=orbit[g1-g2];clusters=ConformalIBP`Private`badClusters[f,#]& /@ {g1,g2};
checks=<|"EachBareIntegralHasOnlyTwoDisjointLogCollisions"->(clusters==={{{1,2},{3,4}},{{1,2},{3,4}}}),
 "ConformalWeights"->And@@(ConformalIBP`Private`weights[f,List@@#]==={4,4,4,4}& /@ {g1,g2}),
 "AllPairResiduesZero"->And@@(ConformalIBP`Private`zero[residue[images,{#}]]& /@ pairs),
 "AllDisjointForestResiduesZero"->And@@(ConformalIBP`Private`zero[residue[images,#]]& /@ forests),
 "BareNegativeControl"->!ConformalIBP`Private`zero[residue[orbit[g1],{First[pairs]}]],
 "SumNegativeControl"->!ConformalIBP`Private`zero[residue[orbit[g1+g2],{First[pairs]}]],
 "DefaultValidatorRemainsConservative"->!FiniteIntegralQ[f,g1-g2]|>;
<|"OrbitSize"->Length[images],"Checks"->checks|>,{pairOfIntegrals,cases}];
Print[results];
Quit[If[And@@Flatten[Values[#["Checks"]]& /@ results] && $MessageList==={},0,1]];
