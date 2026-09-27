root=DirectoryName[DirectoryName[$InputFileName]];Get[FileNameJoin[{root,"Kernel","ConformalIBP.wl"}]];
Get[FileNameJoin[{root,"Examples","kinematics.wl"}]];
If[!TrueQ[InitializeFiniteFlow["/home/april/Packages/finiteflow","/home/april/Packages/finiteflow/mathlink"]],Quit[1]];
FiniteFlow`FFNThreads=24;
out=FileNameJoin[{root,"runs","critical-count-20260923","one-loop-top"}];If[!DirectoryQ[out],CreateDirectory[out,CreateIntermediateDirectories->True]];
f=LadderFamily[1,kinematics,{x,y}];top=G[1,1,1,1,1];
first=DifferentiateIntegrals[f,{top}];second=DifferentiateIntegrals[f,Flatten[Values[first["Rows"]]]];
raw={top,First[first["Rows"][x]],First[first["Rows"][y]],second["Rows"][x][[1]],second["Rows"][x][[2]],second["Rows"][y][[2]]};
monomials={1,dx,dy,dx^2,dx dy,dy^2};
Print[<|"Event"->"TopDerivativeAnsatz","DerivativeOrders"->{0,1,2},"Queries"->Length[raw],"OldDERead"->False,"KnownMIRead"->False|>];
pool=GenerateSystem[f,ConformalIBP`Private`support[raw],"SeedGeometry"->"InverseTargets","InverseOperatorPolicy"->"Complete","Workers"->6,"ProgressFunction"->Print];
If[FailureQ[pool],Print[pool];Quit[2]];
red=ReduceIntegrals[f,raw,pool["Equations"],"Solver"->"FiniteFlow","NumericalVerificationPoints"->{{7338376896737913617,7718278679044643367}},"ProgressFunction"->Print];
If[FailureQ[red],Print[red];Quit[3]];
images=red["ReducedTargets"];atoms=Join[ConformalIBP`Private`support[images],ConformalIBP`Private`sources[images]];
matrix=ConformalIBP`Private`coeff[images,atoms];cvars=Array[TopCoefficient,Length[raw]];
rules=FiniteFlow`FFSparseSolve[(#==0& /@ (Transpose[matrix].cvars)),Reverse[cvars],"Parameters"->{x,y}];
If[!ListQ[rules],Print[rules];Quit[4]];
free=Complement[cvars,First /@ rules];
vectors=Table[Together /@ ((cvars/.rules)/.Thread[free->UnitVector[Length[free],k]]),{k,Length[free]}];
residuals=ConformalIBP`Private`canonicalLinear /@ (vectors.images);
If[!AllTrue[residuals,#===0&],Print[residuals];Quit[5]];
operators=(ConformalIBP`Private`operatorNormalize[#, {dx,dy}]& /@ (vectors.monomials));
bound=TopAnnihilatorRankBound[operators,{dx,dy},{x,y}];
certificate=<|"Family"->f,"Top"->top,"RawDerivativeExpressions"->raw,"DerivativeMonomials"->monomials,
 "IBPSystem"->pool,"Reduction"->red,"RelationVectors"->vectors,"Operators"->operators,
 "ReducedOperatorResiduals"->residuals,"AllBoundaryTermsRetained"->True,"Bound"->bound,
 "OldDERead"->False,"KnownMIRead"->False,"DECampaignRun"->False|>;
Put[certificate,FileNameJoin[{out,"TopBoundCertificate.wl"}]];
Print[<|"Event"->"TopBoundComputed","Identities"->Length[operators],"Bound"->If[FailureQ[bound],bound,bound["UpperBound"]],"OldDERead"->False,"KnownMIRead"->False|>];
Quit[If[FailureQ[bound],6,0]];
