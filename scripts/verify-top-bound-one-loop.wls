root=DirectoryName[DirectoryName[$InputFileName]];Get[FileNameJoin[{root,"Kernel","ConformalIBP.wl"}]];
InitializeFiniteFlow["/home/april/Packages/finiteflow","/home/april/Packages/finiteflow/mathlink"];
out=FileNameJoin[{root,"runs","critical-count-20260923","one-loop-top"}];c=Get[FileNameJoin[{out,"TopBoundCertificate.wl"}]];
f=c["Family"];pool=ConformalIBP`Private`canonExpr[f,#]& /@ c["IBPSystem"]["Equations"];r=c["Reduction"];
rules=Select[r["Rules"],!ConformalIBP`Private`zero[First[#]-Last[#]]&];pivots=First /@ rules;
triangular=DuplicateFreeQ[pivots]&&Intersection[pivots,Join[ConformalIBP`Private`support[Last /@ rules],ConformalIBP`Private`sources[Last /@ rules]]]==={};
res=ConformalIBP`Private`canonicalLinear /@ (pool/.Dispatch[rules]);exact=AllTrue[res,#===0&];
FiniteFlow`FFNewGraph[gr];FiniteFlow`FFGraphInputVars[gr,inn,{x,y}];
FiniteFlow`FFAlgSparseSolver[gr,node,{inn},{x,y},#==0& /@ pool,r["ColumnOrder"],"NeededVars"->r["ColumnOrder"]];
FiniteFlow`FFSolverSparseOutput[gr,node];FiniteFlow`FFGraphOutput[gr,node];learn=FiniteFlow`FFSparseSolverLearn[gr,r["ColumnOrder"]];
point={7338376896737913617,7718278679044643367};values=FiniteFlow`FFGraphEvaluateMany[gr,{point},"NThreads"->1];FiniteFlow`FFDeleteGraph[gr];
If[!MatchQ[values,{_List}],Quit[2]];nrules=FiniteFlow`FFSparseSolverSol[First[values],learn];rank=Length[nrules];
(* Exact containment plus an equal-rank finite-field witness proves equality
   of the original rational row space and the normalized relation row space. *)
span=triangular&&exact&&rank===Length[rules];
opres=ConformalIBP`Private`canonicalLinear /@ ((c["RelationVectors"].c["RawDerivativeExpressions"]/.g_G:>CanonicalIntegral[f,g])/.Dispatch[rules]);
bound=TopAnnihilatorRankBound[c["Operators"],c["Bound"]["DerivativeVariables"],f["Variables"]];
passed=span&&AllTrue[opres,#===0&]&&AssociationQ[bound]&&bound["UpperBound"]===4;
result=<|"Passed"->passed,"ExactOriginalPoolContainment"->exact,"NormalizedIndependentRules"->Length[rules],
 "OriginalPoolRankWitness"->rank,"ExactRationalRowSpacesEqual"->span,"OperatorResiduals"->opres,
 "CertifiedTopUpperBound"->If[passed,4,Missing["NotCertified"]],"DerivativeStaircase"->If[AssociationQ[bound],bound["StandardDerivativeExponents"],{}],
 "Point"->point,"Prime"->FiniteFlow`FFPrimeNo[0],"VerificationPoints"->1,
 "OldDERead"->False,"KnownMIRead"->False,"DECampaignRun"->False|>;
Put[result,FileNameJoin[{out,"IndependentVerification.wl"}]];Export[FileNameJoin[{out,"IndependentVerification.json"}],result,"RawJSON"];Print[result];Quit[If[passed,0,3]];
