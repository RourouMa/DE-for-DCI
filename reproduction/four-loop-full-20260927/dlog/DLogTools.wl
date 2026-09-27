(* Constant-residue dlog decomposition. All linear algebra below is on
   exact constant rational sample matrices, never on kinematic matrices. *)
ClearAll[DCIDLogZeroQ,DCIDLogFactorList,DCIFindConstantDLog];
DCIDLogZeroQ[e_]:=SameQ[Cancel[Together[e]],0];
DCIDLogFactorList[matrices_List,vars_List]:=Module[{fs},
 fs=DeleteDuplicates[First /@ Flatten[(Rest[FactorList[Denominator[Together[#]]]]& /@ DeleteCases[Flatten[matrices],0]),1]];
 DeleteDuplicates[Sort[(If[Last[Last[CoefficientRules[#,vars]]]<0,-#,#]& /@ fs)]]
];
Options[DCIFindConstantDLog]={"SamplePoints"->{{2,3},{3,5},{5,7},{7,11},{11,13},{13,17},{17,19},{19,23},{23,29},{29,31},{31,37},{37,41},{41,43},{43,47},{47,53},{53,59},{59,61},{61,67},{67,71},{71,73}},"Verify"->True};
DCIFindConstantDLog[ax_List,ay_List,letters_List,vars:{vx_,vy_},OptionsPattern[]]:=Module[
 {fx,fy,points,kernels,rows,modrows,rref,pivots,selected,targets,coef,residues,rx,ry,n=Length[ax],p=1000000007,samples,rank},
 fx=Cancel[D[#,vx]/#]& /@ letters;fy=Cancel[D[#,vy]/#]& /@ letters;
 points=Select[OptionValue["SamplePoints"],FreeQ[Join[fx,fy]/.Thread[vars->#],Indeterminate|_DirectedInfinity]&];
 kernels=Flatten[Table[{fx,fy}/.Thread[vars->pt],{pt,points}],1];
 modrows=Map[Mod[Numerator[#]*PowerMod[Denominator[#],-1,p],p]&,kernels,{2}];
 rref=RowReduce[Transpose[modrows],Modulus->p];
 pivots=DeleteCases[(If[AllTrue[#,SameQ[#,0]&],Nothing,First[FirstPosition[#,a_/;a!=0]]])& /@ rref,Nothing];rank=Length[pivots];
 If[rank=!=Length[letters],Return[Failure["DependentLetters",<|"Rank"->rank,"Letters"->Length[letters]|>]]];
 selected=kernels[[pivots]];
 targets=Table[samples=points[[Ceiling[k/2]]];Flatten[If[OddQ[k],ax,ay]/.Thread[vars->samples]],{k,pivots}];
 coef=LinearSolve[selected,targets];
 residues=ArrayReshape[#,{n,n}]& /@ coef;
 rx=Map[Cancel[Together[#]]&,ax-Sum[residues[[k]] fx[[k]],{k,Length[letters]}],{2}];
 ry=Map[Cancel[Together[#]]&,ay-Sum[residues[[k]] fy[[k]],{k,Length[letters]}],{2}];
 <|"Letters"->letters,"ResidueMatrices"->residues,"XResidual"->rx,"YResidual"->ry,
 "Passed"->AllTrue[Flatten[{rx,ry}],SameQ[#,0]&],"ConstantResidues"->FreeQ[residues,vx|vy],
 "IndependentSamplingRows"->pivots,"SamplingPoints"->points,"Method"->"Exact rational sample solve followed by full symbolic reconstruction"|>
];
