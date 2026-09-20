(* Preserve a compact rational coefficient for each integral, as in itCanon. *)
SnapshotLinearNormal[expr_]:=Module[{vars=Union[Cases[{expr},_G|_G3,Infinity]],a},
 If[vars==={},Return[Together[expr]]];
 a=CoefficientArrays[{expr},vars];
 If[Length[a]>2,Print["Nonlinear integral expression in snapshot composition"];Abort[]];
 First[Normal[a[[1]]]]+If[Length[a]<2,0,(Together /@ First[Normal[a[[2]]]]).vars]];
