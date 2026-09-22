(* Positive powers require an explicitly declared denominator slot. *)
Clear[ibp4DenominatorTemplatesQ,ibp4SeedSupportFitsQ];
ibp4DenominatorTemplatesQ[templates_List]:=Length[templates]>0 &&
 And@@(ListQ[#] && VectorQ[#,IntegerQ] && DuplicateFreeQ[#] &&
   Complement[#,Range[22]]==={}& /@ templates);
ibp4SeedSupportFitsQ[vectors_List,templates_List]:=Module[{positive},
 If[!ibp4DenominatorTemplatesQ[templates] ||
   !And@@(VectorQ[#,IntegerQ] && Length[#]===22& /@ vectors),Return[False]];
 positive=Union[Flatten[Position[#,_?Positive]& /@ vectors]];
 AnyTrue[templates,Complement[positive,#]==={}&]
];
