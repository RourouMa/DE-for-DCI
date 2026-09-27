(* Exact rational cancellation among already finite constant physical expressions.
   These are candidate combinations only: quotient-span membership is checked later. *)

constantPoleCancellationCandidates[f_Association,input_List]:=Module[
 {candidates,added={},audit={},bad,ids,m,kernel,new,all,weights,threshold,checks},
 candidates=DeleteDuplicates[Select[input,constantCombinationQ[#]&&cachedFiniteCandidateQ[f,#]&]];
 Do[
  all=DeleteDuplicates[Join[candidates,added]];
  bad=Select[support[all],representativePoleExcess[f,#]>=threshold&];
  ids=Select[Range[Length[all]],Intersection[support[all[[#]]],bad]=!={}&];
  If[ids==={},AppendTo[audit,<|"ExcessThreshold"->threshold,"HighPoleCandidates"->0,"CancellationDirections"->0|>];Continue[]];
  m=coeff[all[[ids]],bad];
  If[!MatrixQ[m,MatchQ[#,_Integer|_Rational]&],Return[fail["NonRationalConstantPoleCancellation","Candidate coefficients are not exact rational constants."]]];
  kernel=NullSpace[Transpose[m]];
  checks=If[kernel==={},True,And@@(AllTrue[#,TrueQ[#===0]&]& /@ (kernel.m))];
  If[!checks,Return[fail["ConstantPoleCancellationCertificate","Exact pole coefficient cancellation failed."]]];
  new=If[kernel==={},{},canonicalLinear /@ (kernel.all[[ids]])];new=DeleteCases[DeleteDuplicates[new],0];
  new=Select[new,FreeQ[#,Alternatives@@bad]&&cachedFiniteCandidateQ[f,#]&];
  added=DeleteDuplicates[Join[added,new]];
  AppendTo[audit,<|"ExcessThreshold"->threshold,"HighPoleCandidates"->Length[ids],"HighPoleAtoms"->Length[bad],
   "CancellationDirections"->Length[kernel],"NonzeroFiniteCandidates"->Length[new],"ExactRationalCancellation"->checks|>],{threshold,{3,2,1}}];
 <|"Candidates"->Complement[added,candidates],"Audit"->audit,"NoKinematicCoefficients"->True,"ProductionAccepted"->False|>];
