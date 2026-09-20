(* Ordinary IBP action when no double loop-loop pole triggers contact terms.
   This is the same operator, with its linear index coefficients precomputed. *)
factorContract[e_]:=Expand[e]/.{v[a_] v[b_]:>sp[a,b],v[a_]^2:>sp[a,a]};
factorLaurentTemplate[op_]:=factorLaurentTemplate[op]=Module[
 {vars,coef,div,transport,prolist,kernel,den,cr,shifts,coefficients,arrays},
 If[!PolynomialQ[op,Propagators4],Return[$Failed]];
 vars=Select[Variables[op],Head[#]===d&];coef=Coefficient[op,#]& /@ vars;
 div=Total[MapThread[Dsp[#1,#2[[1]]]&, {coef,vars}]];
 transport=factorContract /@ Table[Total[MapThread[
  Dsp[Propagators[[j]],#2[[1]]] #1&, {coef,vars}]],{j,22}];
 prolist=Intersection[Select[Variables[op],Head[#]===pro&],pro /@ DeltaPropagatorIDs];
 kernel=Together[(div-Sum[factorPower[j] transport[[j]]/Propagators[[j]],{j,22}]-
  Total[factorPower[#[[1]]] Coefficient[op,#]& /@ prolist])/.Kinematics];
 If[!FreeQ[kernel,_v|_d|_pro],Return[$Failed]];
 If[kernel===0,Return[<|"Zero"->True|>]];
 den=CoefficientRules[Denominator[kernel],Propagators4];
 If[Length[den]!=1,Return[$Failed]];
 cr=CoefficientRules[Expand[Numerator[kernel]],Propagators4];
 shifts=First /@ cr-ConstantArray[den[[1,1]],Length[cr]];
 coefficients=(Last /@ cr)/den[[1,2]];
 arrays=CoefficientArrays[coefficients,Array[factorPower,26]];
 If[Length[arrays]>2,Return[$Failed]];
 <|"Zero"->False,"Shifts"->shifts,"Constant"->Normal[arrays[[1]]],
  "Linear"->If[Length[arrays]==2,Normal[arrays[[2]]],ConstantArray[0,{Length[cr],26}]]|>
];
factorLaurentIBP[op_,prop_,seed_G]:=Module[{t=factorLaurentTemplate[op],a=List@@seed,c,raw,gs},
 If[t===$Failed,Return[Operator2IBP[op,prop,seed]]];
 If[TrueQ[t["Zero"]],Return[0]];
 c=Together /@ (t["Constant"]+t["Linear"].a);
 raw=DropBadDeltaIntegrals[Total[MapThread[#1 (G@@(a-#2))&,{c,t["Shifts"]}]]];
 gs=Union[Cases[{raw},_G,Infinity]];
 If[And@@(factorFiniteQ /@ gs) && FreeQ[raw,_sp],raw,False]
];
