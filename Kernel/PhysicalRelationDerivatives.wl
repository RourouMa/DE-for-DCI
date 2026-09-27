(* The caller supplies complete physical identities, with original provenance.
   Highest-loop quotient equations or reduced rules are not admissible parents. *)
DifferentiatePhysicalRelations[f_Association,parents_List]:=Module[{der,rows},
 If[!FreeQ[parents,_BoundaryIntegral]||!AllTrue[parents,TrueQ[FiniteIntegralQ[f,#]]&],
  Return[fail["PhysicalDerivativeParents","Require complete, native-finite physical identities without lower-loop sources."]]];
 der=DifferentiateIntegrals[f,parents];If[FailureQ[der],Return[der]];
 rows=DeleteCases[Union[canonExpr[f,#]& /@ Flatten[Values[der["Rows"]],1]],0];
 If[AnyTrue[rows,FailureQ]||!FreeQ[rows,_BoundaryIntegral]||!AllTrue[support[rows],validIntegral[f,#]&&domainQ[f,#]&],Return[fail["PhysicalDerivativeDomain","Generated identities failed source or domain checks."]]];
 <|"Equations"->rows,"OriginalRows"->parents,"NativeDifferentiation"->der,"FamilyHash"->f["Hash"],"ImplementationHash"->$implementationHash,
 "Report"-><|"GeneratedRelations"->Length[rows],"SelectedWholeIdentitiesNativelyFinite"->True,"OriginalPhysicalRowsSourceFree"->True,"GeneratedRelationsSourceFree"->True,
 "KinematicCoefficientDerivativesRetained"->True,"NoProjectedRulesAdmitted"->True,"ParentPoolMembershipMustBeVerifiedByCaller"->True|>|>];
