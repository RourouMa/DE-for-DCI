(* Compile the existing ToLowerLoop contact term separately from the ordinary
   Laurent action. No G3 term is projected away in this generator. *)
contactDeltaVector=Join[ConstantArray[0,22],ConstantArray[1,4]];
contactMonomials[op_]:=contactMonomials[op]=CoefficientRules[Expand[op],Propagators4];
contactMergeMatrix[edge_]:=contactMergeMatrix[edge]=Module[{pair=List@@Propagators4[[edge]],r},
 r=Last[pair]->First[pair];
 Transpose[UnitVector[26,First[FirstPosition[Propagators4,#]]]& /@ (Propagators/.r)]];
contactData[op_,ll_]:=contactData[op,ll]=Module[{cr=contactMonomials[op],indices,parts,edge,pair,c,ds},
 indices=Table[ds=First /@ Select[Variables[cr[[k,2]]],Head[#]===d&];
  Select[Flatten[Position[cr[[k,1,17;;19]]-ll,-2]],
   Intersection[List@@Propagators4[[16+#]],ds]=!={}&],{k,Length[cr]}];
 If[AnyTrue[indices,Length[#]>1&],Return[<|"Blocked"->True|>]];
 parts=Table[If[indices[[k]]==={},Nothing,
  edge=16+First[indices[[k]]];pair=List@@Propagators4[[edge]];c=cr[[k,2]];
  ds=Select[Variables[c],Head[#]===d && MemberQ[pair,First[#]]&];
  c=Together[(-2 Total[(Coefficient[c,#]/sp[inf,#[[1]]])& /@ ds]/.
     v[z_]:>sp[inf,z])/.Last[pair]->First[pair]];
  If[c===0,Nothing,<|"Edge"->edge,"Shift"->Take[cr[[k,1]],22]+2 UnitVector[22,edge],
    "Coefficient"->(c/.Kinematics)|>]],{k,Length[cr]}];
 <|"Blocked"->False,"Parts"->parts|>
];
contactLaurentIBP[op_,prop_,seed_G]:=Module[{a=List@@seed,t,ct,c,raw,contact,labels},
 If[prop=!=Propagators4,Return[Operator2IBP[op,prop,seed]]];
 t=factorLaurentTemplate[op];If[t===$Failed,Return[Operator2IBP[op,prop,seed]]];
 ct=contactData[op,a[[17;;19]]];If[TrueQ[ct["Blocked"]],Return[0]];
 raw=If[TrueQ[t["Zero"]],0,c=Together /@ (t["Constant"]+t["Linear"].a);
  Total[MapThread[#1 (G@@(a-#2))&,{c,t["Shifts"]}]]];
 contact=Total[Function[p,p["Coefficient"] (G@@(contactDeltaVector+
   contactMergeMatrix[p["Edge"]].(Take[a,22]-p["Shift"])))] /@ ct["Parts"]];
 raw=DropBadDeltaIntegrals[raw+contact];
 labels=Union[Cases[{raw},_G|_G3,Infinity]];
 raw=Total[(Together[Coefficient[raw,#]] #)& /@ labels];
 If[And@@(factorFiniteQ /@ Union[Cases[{raw},_G,Infinity]]) && FreeQ[raw,_sp],raw,False]
];
