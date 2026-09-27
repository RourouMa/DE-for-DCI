(* This is an operational relation-repair gate, not a proof of infinite dimension.
   Track the same atoms at successive first appearances, never marginal maxima. *)
growthChainPointRows[rows_List,prime_Integer]:=Module[{atoms=support[rows],matrix,mod},
 mod[q_]:=With[{v=Together[q]},If[MatchQ[v,_Integer|_Rational]&&Mod[Denominator[v],prime]=!=0,
  Mod[Numerator[v]PowerMod[Denominator[v],-1,prime],prime],$Failed]];
 If[atoms==={},Return[ConstantArray[0,Length[rows]]]];
 matrix=Map[mod,coeff[rows,atoms],{2}];
 If[!MatrixQ[matrix,IntegerQ],Return[fail["GrowthChainPointPole","Chain support requires regular finite-field coefficients."]]];
 matrix.atoms];

AssessGrowthChains[f_Association,history_Association,rows_List,round_Integer,threshold_Integer:3]:=Module[
 {seen=Lookup[history,"FirstAppearance",<||>],atoms=support[rows],pairs,groups,chains={},path,ordered,a,b,key,d,found,targets},
 If[threshold<1,Return[fail["GrowthChainThreshold","Use a positive growth-step threshold."]]];
 Do[If[!KeyExistsQ[seen,g],AssociateTo[seen,g->round]],{g,atoms}];
 pairs=Select[Subsets[Range[Length[f["Propagators"]]],{2}],f["Supports"][[#[[1]]]]===f["Supports"][[#[[2]]]]&];pairs=Join[pairs,Reverse /@ pairs];
 Do[
  groups=GatherBy[Keys[seen],Function[g,a=List@@g;{ReplacePart[a,Thread[pair->0]],Total[a[[pair]]]}]];
  Do[
   ordered=SortBy[group,-(List@@#)[[First[pair]]]&];path={};
   Do[
    If[path==={},path={g},
     a=List@@Last[path];b=List@@g;
     If[b[[First[pair]]]===a[[First[pair]]]-1&&seen[g]>seen[Last[path]],AppendTo[path,g],
      If[Length[path]-1>=threshold,AppendTo[chains,<|"Direction"->{{pair[[1]],-1},{pair[[2]],1}},"Atoms"->path,"FirstAppearanceRounds"->(seen[#]& /@ path),"GrowthSteps"->(Length[path]-1)|>]];path={g}]],{g,ordered}];
   If[Length[path]-1>=threshold,AppendTo[chains,<|"Direction"->{{pair[[1]],-1},{pair[[2]],1}},"Atoms"->path,"FirstAppearanceRounds"->(seen[#]& /@ path),"GrowthSteps"->(Length[path]-1)|>]],{group,groups}],{pair,pairs}];
 chains=DeleteDuplicates[chains];
 targets=Union[Flatten[Table[d=ConstantArray[0,Length[List@@First[c["Atoms"]]]];Do[d[[p[[1]]]]=p[[2]],{p,c["Direction"]}];
 Select[Table[G@@((List@@First[c["Atoms"]])+j d),{j,-2,1}],validIntegral[f,#]&&domainQ[f,#]&],{c,chains}],1]];
 <|"FirstAppearance"->seen,"Round"->round,"Threshold"->threshold,"Triggered"->(chains=!={}),"Chains"->chains,"RepairTargets"->targets,
 "SearchScope"->"Fixed unit transfers between propagators with equal loop support; all other indices fixed",
 "Decision"->If[chains==={},"Continue","RelationRepairRequired"],"InfiniteDimensionalityProved"->False|>];
