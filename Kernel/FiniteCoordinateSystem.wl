(* Assemble a full finite DE from explicit physical candidates at several loop
   orders. No saved DE matrix or reduction rule is admitted as a physical row. *)
(* Reuse only hash-bound complete canonical physical rows. Boundary sources are
   kept and mapped below; no numerical reduction or saved DE is a cache row. *)
readFullCanonicalPhysicalPool[families_Association,path_String]:=Module[{index,record,cf,l,atoms},
 If[!FileExistsQ[path],Return[fail["FullCanonicalPoolIndex","The canonical physical pool index does not exist."]]];
 index=Get[path];If[!AssociationQ[index]||!StringQ[Lookup[index,"File",None]]||!FileExistsQ[index["File"]]||FileHash[index["File"],"SHA256"]=!=Lookup[index,"FileSHA256",None],Return[fail["FullCanonicalPoolHash","The canonical physical pool must match its indexed SHA256."]]];
 record=Block[{poolRows,poolColumns,poolMetadata},Get[index["File"]];<|"Rows"->poolRows,"Columns"->poolColumns,"Metadata"->poolMetadata|>];
 If[!ListQ[record["Rows"]]||!AssociationQ[record["Metadata"]]||Hash[record["Rows"],"SHA256"]=!=Lookup[index,"FullPoolHash",None],Return[fail["FullCanonicalPoolRows","The cached physical rows must match their declared hash."]]];
 cf=Lookup[record["Metadata"],"Family",<||>];l=Lookup[cf,"LoopCount",0];
 If[!KeyExistsQ[families,l]||Lookup[cf,"Hash",None]=!=families[l]["Hash"]||!TrueQ[Lookup[record["Metadata"],"SourceInformationRetained",False]],Return[fail["FullCanonicalPoolFamily","The canonical family must match a declared family and retain all sources."]]];
 atoms=support[record["Rows"]];If[!AllTrue[atoms,validIntegral[families[l],#]&],Return[fail["FullCanonicalPoolShape","Cached G atoms must belong to their declared loop family."]]];
 If[!ListQ[record["Columns"]]||!DuplicateFreeQ[record["Columns"]]||Complement[atoms,record["Columns"]]=!={}||!AllTrue[Select[record["Columns"],MatchQ[#,_G]&],validIntegral[families[l],#]&],Return[fail["FullCanonicalPoolColumns","Cached physical columns must contain all cached G atoms without duplicates; additional valid query columns are permitted."]]];
 <|"Rows"->record["Rows"],"CanonicalAtoms"->atoms,"CanonicalColumns"->Select[record["Columns"],MatchQ[#,_G]&],"Provenance"-><|"Index"->path,"IndexSHA256"->FileHash[path,"SHA256"],"FileSHA256"->index["FileSHA256"],"FullPoolHash"->index["FullPoolHash"],"FamilyHash"->cf["Hash"],"LoopCount"->l,"Rows"->Length[record["Rows"]]|>|>];
Options[ReconstructFiniteCoordinateSystem]={"OutputDirectory"->None,"Workers"->4,"VerificationPoint"->{11,17},"Provenance"-><||>,"CanonicalPhysicalPoolCaches"->{}};
ReconstructFiniteCoordinateSystem[families_Association,basis_List,original_List,equations_List,OptionsPattern[]]:=Module[
 {out=OptionValue["OutputDirectory"],threads=OptionValue["Workers"],pt=OptionValue["VerificationPoint"],vars,sizes,loopOf,canG,canUncached,canB,map,finitePart,derivative,atomDerivative,
  physicalBasis,physicalTop,physicalDE,allBasisAtoms,finite,rawAtoms,sourceAtoms,sourceMap,rows,syms,columns,queries,f,poolHash,
  graph,in,sys,witness,cols,learn,values,count,ids,numericalRules,prime,point,reference,selected,benchmarkFile,manifestFile,
  coordinates,n,matrices,topCoordinates,curvature,mod,flat,report,result,started=AbsoluteTime[],file,
  cachePaths=OptionValue["CanonicalPhysicalPoolCaches"],caches,canonicalAtoms,physicalEquations,cacheProvenance,cachedColumns,presentColumns,freshColumns,columnGroups},
 If[!StringQ[out]||!MemberQ[$Packages,"FiniteFlow`"]||families===<||>,Return[fail["FullCoordinateInput","Supply families, an output directory and initialized FiniteFlow."]]];
 If[!AllTrue[Keys[families],IntegerQ[#]&&#>0&&Lookup[families[#],"LoopCount",None]===#&&KeyExistsQ[families[#],"Supports"]&],Return[fail["FullCoordinateFamilies","Map each loop count to a complete family returned by CreateFamily."]]];
 If[!ListQ[cachePaths]||!VectorQ[cachePaths,StringQ],Return[fail["FullCanonicalPoolOption","CanonicalPhysicalPoolCaches must be a list of canonical physical pool index paths."]]];
 caches=readFullCanonicalPhysicalPool[families,#]& /@ cachePaths;If[AnyTrue[caches,FailureQ],Return[First[Select[caches,FailureQ]]]];
 canonicalAtoms=Association[(#->True)& /@ DeleteDuplicates[Flatten[Lookup[caches,"CanonicalAtoms",{}]]]];
 physicalEquations=Join[equations,Flatten[Lookup[caches,"Rows",{}],1]];cacheProvenance=Lookup[caches,"Provenance",{}];
 If[FileExistsQ[FileNameJoin[{out,"DifferentialEquations.wl"}]],Return[fail["FullCoordinateExists","Use a fresh output directory."]]];
 If[!DirectoryQ[out],CreateDirectory[out,CreateIntermediateDirectories->True]];
 vars=First[Values[families]]["Variables"];
 If[!AllTrue[Values[families],#["Variables"]===vars&&#["Kinematics"]===First[Values[families]]["Kinematics"]&]||Length[pt]=!=Length[vars],Return[fail["MixedKinematics","All loop families must share the same variables and kinematics."]]];
 sizes=Association@KeyValueMap[(Length[FamilyPropagators[#2]]->#1)&,families];
 loopOf[g_G]:=Lookup[sizes,Length[List@@g],0];
 If[!AllTrue[support[basis],KeyExistsQ[families,loopOf[#]]&&representativePoleLimitsQ[families[loopOf[#]],#]&],Return[fail["MixedBasisPowerLimits","Finite representatives must have external-loop denominator powers <=3 and loop-loop powers <=2."]]];
 canUncached[g_G]:=canUncached[g]=If[KeyExistsQ[families,loopOf[g]],CanonicalIntegral[families[loopOf[g]],g],fail["MixedIntegralShape","No declared loop family matches an integral."]];
 canG[g_G]:=If[KeyExistsQ[canonicalAtoms,g],g,canUncached[g]];
 canB[b_BoundaryIntegral]:=Module[{mapped},If[!KeyExistsQ[families,b[[1]]],Return[b]];mapped=canG[G@@b[[2]]];If[FailureQ[mapped],b,mapped]];
 map[e_]:=Module[{a=support[e],b=sources[e],images},images=Join[canG /@ a,canB /@ b];If[AnyTrue[images,FailureQ],Return[First[Select[images,FailureQ]]]];canonicalLinear[e/.Dispatch[Thread[Join[a,b]->images]]]];
 physicalBasis=map /@ basis;physicalTop=map /@ original;
 If[AnyTrue[Join[physicalBasis,physicalTop],FailureQ]||sources[{physicalBasis,physicalTop}]=!={},Return[fail["MixedCanonicalization","A candidate or original input is outside the declared domains."]]];
 finitePart[e_]:=AllTrue[GatherBy[support[e],loopOf],Function[gs,With[{part=Total[(Coefficient[Expand[e],#] #)& /@ gs]},TrueQ[FiniteIntegralQ[families[loopOf[First[gs]]],part]]]]];
 finite=AllTrue[physicalBasis,finitePart];If[!finite,Return[fail["MixedFiniteBasis","Every whole loop component must be natively finite."]]];
 atomDerivative[g_G,z_]:=atomDerivative[g,z]=Module[{d=DifferentiateIntegrals[families[loopOf[g]],{g}]},If[FailureQ[d],d,First[d["Rows"][z]]]];
 derivative[e_,z_]:=map[D[e,z]+Total[(Coefficient[Expand[e],#] atomDerivative[#,z])& /@ support[e]]];
 physicalDE=Flatten[Table[derivative[#,z]& /@ physicalBasis,{z,vars}],1];If[AnyTrue[physicalDE,FailureQ],Return[fail["MixedDerivative","Native complete differentiation failed."]]];
 Print[<|"Event"->"FullMixedPhysicalPreparation","BasisCount"->Length[basis],"InputPhysicalRows"->Length[physicalEquations],"CanonicalCacheCount"->Length[caches],"CachedCanonicalAtoms"->Length[canonicalAtoms]|>];
 sourceAtoms=sources[physicalEquations];sourceMap=canB /@ sourceAtoms;If[AnyTrue[sourceMap,FailureQ],Return[fail["MixedSourceMapping","Some physical source has no declared mapping."]]];
 Print[<|"Event"->"FullMixedSourcesMapped","SourceColumns"->Length[sourceAtoms],"Seconds"->N[AbsoluteTime[]-started]|>];
 rows=physicalEquations/.Dispatch[Thread[sourceAtoms->sourceMap]];rawAtoms=support[{rows,physicalBasis,physicalDE,physicalTop}];
 syms=rawAtoms-(canG /@ rawAtoms);If[!FreeQ[syms,_Failure],Return[fail["MixedSymmetry","A physical atom has no allowed symmetry representative."]]];
 rows=DeleteCases[Union[rows,syms],0];
 (* Column order affects elimination cost, not the explicit physical basis.
    Reuse the hash-bound cache order instead of repeating finiteness/ordering
    work for every high-loop column in an already canonical complete pool. *)
 presentColumns=Association[(#->True)& /@ support[rows]];
 cachedColumns=Select[DeleteDuplicates[Flatten[Lookup[caches,"CanonicalColumns",{}]]],KeyExistsQ[presentColumns,#]&];
 freshColumns=Complement[Keys[presentColumns],cachedColumns];
 Print[<|"Event"->"FullMixedColumnOrdering","ReusedColumns"->Length[cachedColumns],"FreshColumns"->Length[freshColumns],"Seconds"->N[AbsoluteTime[]-started]|>];
 freshColumns=SortBy[freshColumns,Function[g,{-loopOf[g],simpleKey[families[loopOf[g]],g]}]];
 columnGroups=GroupBy[Join[cachedColumns,freshColumns],loopOf];
 columns=Join[Flatten[Lookup[columnGroups,ReverseSort[Keys[families]],{}],1],sources[rows]];
 queries=Join[support[{physicalBasis,physicalDE,physicalTop}],sources[{physicalBasis,physicalDE,physicalTop}]];poolHash=Hash[rows,"SHA256"];
 f=<|"Variables"->vars,"Hash"->Hash[{"FullPhysicalCoordinateFamilies",Lookup[Values[families],"Hash"]},"SHA256"],"SourceTreatment"->"RetainAll"|>;
 file=FileNameJoin[{out,"PhysicalPool.mx"}];Block[{fullCoordinatePool=<|"Rows"->rows,"Columns"->columns,"Families"->families,"PoolHash"->poolHash,"Provenance"->OptionValue["Provenance"],"CanonicalPhysicalPoolCaches"->cacheProvenance|>},DumpSave[file,fullCoordinatePool]];
 witness=Unique["fullCoordinateWitness"];cols=Join[{witness},columns,Complement[queries,columns]];
 FiniteFlow`FFNewGraph[graph];FiniteFlow`FFGraphInputVars[graph,in,vars];
 Print[<|"Event"->"FullMixedPhysicalPoolLearning","BasisCount"->Length[basis],"Rows"->Length[rows],"Queries"->Length[queries]|>];
 FiniteFlow`FFAlgSparseSolver[graph,sys,{in},vars,#==0& /@ Prepend[rows,witness-First[queries]],cols,"NeededVars"->Append[queries,witness]];
 FiniteFlow`FFSolverSparseOutput[graph,sys];FiniteFlow`FFGraphOutput[graph,sys];learn=FiniteFlow`FFSparseSolverLearn[graph,cols];values=FiniteFlow`FFGraphEvaluateMany[graph,{pt},"NThreads"->1];
 If[!ListQ[learn]||!MatchQ[values,{_List}],FiniteFlow`FFDeleteGraph[graph];Return[fail["FullCoordinateReference","Independent full-pool numerical solve failed."]]];
 count=FiniteFlow`FFSparseSolverMarkAndSweepEqs[graph,sys];ids=FiniteFlow`FFSolverIndepEqs[graph,sys];FiniteFlow`FFDeleteGraph[graph];
 If[Length[ids]=!=count||!AllTrue[ids,1<=#<=Length[rows]+1&],Return[fail["FullCoordinateSelection","Invalid dependency row indices."]]];
 selected=rows[[Select[ids,#>1&]-1]];numericalRules=Select[FiniteFlow`FFSparseSolverSol[First[values],learn],MatchQ[First[#],_G|_BoundaryIntegral]&];prime=FiniteFlow`FFPrimeNo[0];point=Thread[vars->pt];
 benchmarkFile=FileNameJoin[{out,"Benchmark.mx"}];manifestFile=FileNameJoin[{out,"SourceManifest.mx"}];
 Block[{benchmark=<|"Rows"->selected,"Columns"->columns,"Queries"->queries|>},DumpSave[benchmarkFile,benchmark]];
 Block[{sourceManifest=<|"OriginalEquationsHash"->Hash[selected,"SHA256"],"FullPoolHash"->poolHash,"PhysicalPool"->file,"PhysicalPoolSHA256"->FileHash[file,"SHA256"],"Provenance"->OptionValue["Provenance"],"AllSourcesRetained"->True,"AllSourcesRetainedAndMapped"->FreeQ[rows,_BoundaryIntegral],"UnmappedPoolSources"->sources[rows]|>},DumpSave[manifestFile,sourceManifest]];
 reference=<|"FamilyHash"->f["Hash"],"FullPoolHash"->poolHash,"FullReferenceBenchmark"->benchmarkFile,"FullReferenceSourceManifest"->manifestFile,"FullReferenceQueries"->queries,"FullPoolNumericalRules"->numericalRules,"Point"->pt,"Prime"->prime|>;
 Block[{fullCoordinateReference=reference},DumpSave[FileNameJoin[{out,"FullReference.mx"}],fullCoordinateReference]];
 coordinates=projectRowsInPhysicalBasis[f,Join[physicalBasis,physicalDE,physicalTop],physicalBasis,reference,FileNameJoin[{out,"coordinates"}],threads];If[FailureQ[coordinates],Return[coordinates]];
 n=Length[basis];matrices=Association@MapIndexed[#1->Take[coordinates["Weights"],{n+(First[#2]-1)n+1,n+First[#2]n}]&,vars];topCoordinates=Take[coordinates["Weights"],-Length[original]];
 mod[q_]:=With[{v=Together[q]},If[MatchQ[v,_Integer|_Rational]&&Mod[Denominator[v],prime]=!=0,Mod[Numerator[v]PowerMod[Denominator[v],-1,prime],prime],$Failed]];
 curvature=Table[With[{a=vars[[i]],b=vars[[j]]},Mod[Map[mod,(D[matrices[a],b]-D[matrices[b],a])/.point,{2}]+Map[mod,matrices[a]/.point,{2}].Map[mod,matrices[b]/.point,{2}]-Map[mod,matrices[b]/.point,{2}].Map[mod,matrices[a]/.point,{2}],prime]],{i,Length[vars]},{j,i+1,Length[vars]}];
 flat=AllTrue[Flatten[curvature],SameQ[#,0]&];
 report=<|"FullDEClosed"->TrueQ[flat&&coordinates["FullPoolProjectionAgreement"]],"BasisCount"->n,"BasisLoopCounts"->Counts[ToString[Max[loopOf /@ support[#]]]& /@ physicalBasis],"EveryBasisExpressionFinite"->finite,
 "IndependentBasisPointWitness"->True,"CompletePhysicalPoolAgreement"->True,"OriginalTopRationallyCovered"->True,"FullCurvatureNumericallyZero"->flat,"SymbolicCurvatureChecked"->False,
 "PropagatorPowerLimitsSatisfied"->True,"ExternalLoopPowerLimit"->3,"LoopLoopPowerLimit"->2,
 "CanonicalPhysicalPoolCaches"->cacheProvenance,
 "ReusedPhysicalColumnOrderCount"->Length[cachedColumns],
 "NoSourcesDiscarded"->True,"UnmappedPoolSourceCount"->Length[sources[rows]],"BoundarySourceTreatment"->"RetainAll","OldDEOrReductionRulesUsedAsEquations"->False,"NativeDerivativesRecomputed"->True,"Point"->pt,"Prime"->prime,"FullPoolHash"->poolHash,"ImplementationHash"->$implementationHash,"Seconds"->N[AbsoluteTime[]-started]|>;
 result=<|"Report"->report,"Families"->families,"Basis"->physicalBasis,"Matrices"->matrices,"OriginalInputs"->physicalTop,"OriginalTopCoordinates"->topCoordinates,"PhysicalDerivativeRows"->physicalDE,"SourceManifest"->manifestFile,"CurvatureAtPoint"->curvature|>;
 Put[result,FileNameJoin[{out,"DifferentialEquations.wl"}]];Export[FileNameJoin[{out,"Report.json"}],report,"RawJSON"];Print[report];result];
