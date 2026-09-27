(* Usage: WolframKernel -script verify-physical-coordinate-run.wls RUN FINITEFLOW_ROOT [PACKAGE_ROOT] *)
scriptPosition=FirstPosition[$CommandLine,"-script"];args=If[MissingQ[scriptPosition],Rest[$ScriptCommandLine],Drop[$CommandLine,First[scriptPosition]+1]];If[Length[args]<2,Print["Expected RUN and FINITEFLOW_ROOT"];Quit[1]];
run=ExpandFileName[args[[1]]];lib=ExpandFileName[args[[2]]];package=If[Length[args]>=3,ExpandFileName[args[[3]]],DirectoryName[DirectoryName[$InputFileName]]];
Get[FileNameJoin[{package,"Kernel","ConformalIBP.wl"}]];
candidate=Get[FileNameJoin[{run,"Campaign.wl"}]];
If[!AssociationQ[candidate]||!TrueQ[candidate["HighestLoopCandidateClosed"]],Quit[2]];
f=candidate["Family"];basis=candidate["Basis"];matrices=candidate["Matrices"];vars=f["Variables"];n=Length[basis];
poleAudit=ConformalIBP`Private`representativePoleAudit[f,basis];If[!TrueQ[poleAudit["PropagatorPowerLimitsSatisfied"]],Print[poleAudit];Quit[11]];
If[candidate["ImplementationHash"]=!=ConformalIBP`Private`$implementationHash||Keys[matrices]=!=vars||!AllTrue[Values[matrices],Dimensions[#]==={n,n}&],Quit[3]];
out=FileNameJoin[{run,"independent-verification"}];If[!DirectoryQ[out],CreateDirectory[out]];started=AbsoluteTime[];
If[!TrueQ[InitializeFiniteFlow[lib,FileNameJoin[{lib,"mathlink"}]]],Quit[4]];FiniteFlow`FFNThreads=4;
finite=AllTrue[basis,TrueQ[FiniteIntegralQ[f,#]]&];der=DifferentiateIntegrals[f,basis];If[FailureQ[der],Print[der];Quit[5]];
physicalInput=ConformalIBP`Private`canonExpr[f,#]& /@ basis;
physicalTop=ConformalIBP`Private`canonExpr[f,#]& /@ candidate["OriginalInputs"];
physicalDE=ConformalIBP`Private`canonExpr[f,#]& /@ Flatten[Values[der["Rows"]],1];queries=ConformalIBP`Private`support[{physicalInput,physicalTop,physicalDE}];
index=Get[candidate["FullPoolCacheIndex"]];If[index["FileSHA256"]=!=FileHash[index["File"],"SHA256"]||index["FullPoolHash"]=!=candidate["FullPoolHash"],Quit[6]];
Get[index["File"]];rows=ConformalIBP`Private`poolRows;columns=ConformalIBP`Private`poolColumns;
If[Hash[rows,"SHA256"]=!=candidate["FullPoolHash"],Quit[7]];
witness=Unique["verificationWitness"];cols=Join[{witness},columns,Complement[queries,columns]];
FiniteFlow`FFNewGraph[graph];FiniteFlow`FFGraphInputVars[graph,in,vars];
Print[<|"Event"->"IndependentCompletePhysicalPoolLearning","Rows"->Length[rows],"Queries"->Length[queries]|>];
FiniteFlow`FFAlgSparseSolver[graph,sys,{in},vars,#==0& /@ Prepend[rows,witness-First[queries]],cols,"NeededVars"->Append[queries,witness]];
FiniteFlow`FFSolverSparseOutput[graph,sys];FiniteFlow`FFGraphOutput[graph,sys];learn=FiniteFlow`FFSparseSolverLearn[graph,cols];
values=FiniteFlow`FFGraphEvaluateMany[graph,{{11,17}},"NThreads"->1];If[!ListQ[learn]||!MatchQ[values,{_List}],Quit[8]];
count=FiniteFlow`FFSparseSolverMarkAndSweepEqs[graph,sys];ids=FiniteFlow`FFSolverIndepEqs[graph,sys];FiniteFlow`FFDeleteGraph[graph];
If[Length[ids]=!=count||!AllTrue[ids,1<=#<=Length[rows]+1&],Quit[9]];
selected=rows[[Select[ids,#>1&]-1]];
benchmarkFile=FileNameJoin[{out,"Benchmark.mx"}];manifestFile=FileNameJoin[{out,"SourceManifest.mx"}];
Block[{ConformalIBP`Private`benchmark=<|"Rows"->selected,"Columns"->columns,"Queries"->queries|>},DumpSave[benchmarkFile,ConformalIBP`Private`benchmark]];
Block[{ConformalIBP`Private`sourceManifest=<|"OriginalEquationsHash"->Hash[selected,"SHA256"],"FullPoolHash"->candidate["FullPoolHash"],"FullPoolCacheIndex"->candidate["FullPoolCacheIndex"],"SourceInformationRetained"->True|>},DumpSave[manifestFile,ConformalIBP`Private`sourceManifest]];
rules=Select[FiniteFlow`FFSparseSolverSol[First[values],learn],MatchQ[First[#],_G|_BoundaryIntegral]&];prime=FiniteFlow`FFPrimeNo[0];point=Thread[vars->{11,17}];
image[rr_]:=(((rr/.point)/.Dispatch[rules])/._BoundaryIntegral->0);
mod[q_]:=With[{v=Together[q]},If[MatchQ[v,_Integer|_Rational]&&Mod[Denominator[v],prime]=!=0,Mod[Numerator[v]PowerMod[Denominator[v],-1,prime],prime],$Failed]];
bi=image[physicalInput];di=image[physicalDE];m=Map[mod,ConformalIBP`Private`coeff[bi,ConformalIBP`Private`support[bi]],{2}];
independent=MatrixQ[m,IntegerQ]&&Length[Select[RowReduce[m,Modulus->prime],AnyTrue[#,UnequalTo[0]]&]]===n;
agreement=AllTrue[di-Flatten[Table[(matrices[v]/.point).bi,{v,vars}],1],ConformalIBP`Private`numericalLinearZeroQ[#,prime]&];
curvature=Table[With[{a=vars[[i]],b=vars[[j]]},Mod[Map[mod,(D[matrices[a],b]-D[matrices[b],a])/.point,{2}]+
 Map[mod,matrices[a]/.point,{2}].Map[mod,matrices[b]/.point,{2}]-Map[mod,matrices[b]/.point,{2}].Map[mod,matrices[a]/.point,{2}],prime]],{i,Length[vars]},{j,i+1,Length[vars]}];
flat=AllTrue[Flatten[curvature],SameQ[#,0]&];
reference=<|"FamilyHash"->f["Hash"],"FullPoolHash"->candidate["FullPoolHash"],"FullReferenceBenchmark"->benchmarkFile,"FullReferenceSourceManifest"->manifestFile,
 "FullReferenceQueries"->queries,"FullPoolNumericalRules"->rules,"Point"->{11,17},"Prime"->prime|>;
top=ConformalIBP`Private`projectRowsInPhysicalBasis[f,physicalTop,physicalInput,reference,FileNameJoin[{out,"original-top"}],4];
topPassed=AssociationQ[top]&&TrueQ[top["FullPoolProjectionAgreement"]];
report=<|"Passed"->(finite&&independent&&agreement&&flat&&topPassed),"HighestLoopClosedModuloSources"->(finite&&independent&&agreement&&flat&&topPassed),
 "BasisCount"->n,"PropagatorPowerAudit"->poleAudit,"NativeFiniteness"->finite,"Independent"->independent,"FreshNativeDEFullPoolAgreement"->agreement,"HomogeneousCurvatureAtPointZero"->flat,
 "OriginalTopRationallyCovered"->topPassed,"FullPoolHash"->candidate["FullPoolHash"],"ImplementationHash"->candidate["ImplementationHash"],"Point"->{11,17},"Prime"->prime,
 "SourcesRetained"->True,"FullDEClaimed"->False,"LowerLoopComputed"->False,"Seconds"->N[AbsoluteTime[]-started]|>;
Export[FileNameJoin[{out,"Report.json"}],report,"RawJSON"];Put[<|"Report"->report,"OriginalTopCoordinates"->top,"Curvature"->curvature|>,FileNameJoin[{out,"Verification.wl"}]];Print[report];Quit[If[TrueQ[report["Passed"]],0,10]];
