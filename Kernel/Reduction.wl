(* Exact algebra and finite combinations; no four-loop indices or kinematic names. *)
InitializeFiniteFlow[lib_String,math_String]:=Module[{},
 If[!DirectoryQ[lib] || !FileExistsQ[FileNameJoin[{math,"FiniteFlow.m"}]],Return[fail["FiniteFlowPath","Invalid FiniteFlow installation paths."]]];
 Global`$FiniteFlowLibPath=ExpandFileName[lib];
 If[!MemberQ[$LibraryPath,ExpandFileName[lib]],AppendTo[$LibraryPath,ExpandFileName[lib]]];
 If[!MemberQ[$Path,ExpandFileName[math]],AppendTo[$Path,ExpandFileName[math]]];
 Quiet[Check[Needs["FiniteFlow`"],Return[fail["FiniteFlowLoad","FiniteFlow could not be loaded."]]]];True];

Options[GenerateSystem]=Join[Options[GenerateSeeds],{"Operators"->Automatic,"CompletedApplications"->{},"FiniteSeeds"->{},"CompletedSymmetryInputs"->{},"Workers"->1,"KernelExecutable"->Automatic}];
GenerateSystem[f_Association,targets_List,opts:OptionsPattern[]]:=Module[{plan,done=Association[(#->True)& /@ OptionValue["CompletedApplications"]],
 equations={},attempted={},rejected={},r,key,ops,syms,raw,newSymmetry},
 If[(!IntegerQ[OptionValue["Workers"]] || OptionValue["Workers"]<1),Return[fail["Workers","Workers must be a positive integer."]]];
 If[OptionValue["Workers"]>1,Return[generateSharded[f,targets,Join[Association[Options[GenerateSystem]],Association[{opts}]]]]];
 plan=GenerateSeeds[f,targets,OptionValue["Operators"],Sequence@@FilterRules[Normal[Association[Join[Options[GenerateSystem],{opts}]]],Options[GenerateSeeds]]];If[FailureQ[plan],Return[plan]];ops=plan["Operators"];
 Do[Do[key={Hash[ops[[b["OperatorIndex"]]],"SHA256"],seed};If[KeyExistsQ[done,key],Continue[]];
  r=IBPRelation[f,ops[[b["OperatorIndex"]]],seed];AppendTo[attempted,key];
  If[FailureQ[r],AppendTo[rejected,<|"Application"->key,"Failure"->r|>],If[!zero[r],AppendTo[equations,r]]],
  {seed,b["Seeds"]}],{b,plan["Batches"]}];
 Do[If[OptionValue["SeedDomain"]==="Original" && !originalDomainExpressionQ[f,seed],Continue[]];
  If[!FiniteIntegralQ[f,seed],Continue[]];
  Do[If[ops[[k]]["Degree"]=!=ConstantArray[0,f["LoopCount"]],Continue[]];
   key={Hash[ops[[k]],"SHA256"],seed};If[KeyExistsQ[done,key] || MemberQ[attempted,key],Continue[]];
   r=IBPRelation[f,ops[[k]],seed];AppendTo[attempted,key];
   If[FailureQ[r],AppendTo[rejected,<|"Application"->key,"Failure"->r|>],If[!zero[r],AppendTo[equations,r]]],{k,Length[ops]}],
  {seed,OptionValue["FiniteSeeds"]}];
 raw=Union[support[targets],support[equations]];
 newSymmetry=Complement[raw,OptionValue["CompletedSymmetryInputs"]];
 syms=Table[r=CanonicalIntegral[f,g];If[FailureQ[r],Return[r]];g-r,{g,newSymmetry}];
 equations=DeleteCases[DeleteDuplicates[canonicalLinear /@ Join[equations,syms]],0];
 <|"Equations"->equations,"Applications"->attempted,"RejectedApplications"->rejected,
  "DegreeCoverageGaps"->plan["EmptyDegrees"],"SymmetryInputs"->raw,
  "NewSymmetryInputs"->newSymmetry,"AllGeneratedSupportCanonicalized"->True,"SeedGeometry"->plan["Geometry"],"SeedPolicy"->KeyTake[plan,{"SeedDomain","SeedCenters","BlockExpansion","UnmappedCenters"}],
  "AllActualSeedsInsideOriginalDomain"->And@@(originalDomainExpressionQ[f,Last[#]]& /@ attempted)|>];

simpleKey[f_,g_G]:=Module[{a=List@@g,ps=parts[f,g],ext,boxScore=0},
 ext=Complement[Range[Length[f["Propagators"]]],f["LoopLoopIDs"]];
 Do[With[{v=a[[Select[ext,MemberQ[f["Supports"][[#]],First[block]]&]]]},
  If[Count[v,_?Positive]>1,boxScore+=Total[Max[Abs[#]-2,0]& /@ v]]],{block,Select[ps,Length[#]===1&]}];
 Join[If[Lookup[f,"IntegralOrdering","LadderFirst"]==="LadderFirst",{Boole[originalDomainIntegralQ[f,g]]},{}],{Boole[Length[ps]>1],-Total[Abs[Pick[a[[f["LoopLoopIDs"]]],f["TopSector"][[f["LoopLoopIDs"]]],0]]],
  -boxScore,-Total[Abs[Take[a,Length[f["Propagators"]]]]],-Max[Abs[a]],a}]];
$lastVerifiedReduction=<||>;
reductionTargets[result_,targets_,rows_]:=Module[{dispatch=Dispatch[result["Rules"]],images},
 images=canonicalLinear /@ (targets/.dispatch);
 Join[result,<|"ReducedTargets"->images,"RawMasters"->support[images],"BoundarySources"->sources[images],
  "SelfReducedTargets"->Select[support[targets],zero[(#/.dispatch)-#]&],
  "UnseenTargets"->Complement[support[targets],support[rows]]|>]];
Options[ReduceIntegrals]={"Solver"->Automatic,"MaxExactColumns"->1500,"MaxPrimes"->80,"ProgressFunction"->None,"ReuseVerifiedReduction"->True};
ReduceIntegrals[f_Association,targets_List,equations_List,OptionsPattern[]]:=Module[
 {rows,cols,boundary,all,solver=OptionValue["Solver"],matrix,reduced,pivs,rules,raw,images,residual,canonTargets,stageStart=AbsoluteTime[],timings=<||>,report=OptionValue["ProgressFunction"],stage,cacheKey,reuse,result},
 stage[name_]:=(AssociateTo[timings,name->(AbsoluteTime[]-stageStart)];If[report=!=None,report[<|"Action"->"Reduction stage completed","Stage"->name,"Seconds"->timings[name]|>]];stageStart=AbsoluteTime[]);
 rows=DeleteCases[canonExpr[f,#]& /@ equations,0];If[AnyTrue[rows,FailureQ],Return[First[Select[rows,FailureQ]]]];
 canonTargets=canonExpr[f,#]& /@ targets;If[AnyTrue[canonTargets,FailureQ],Return[First[Select[canonTargets,FailureQ]]]];
 stage["Canonicalization"];
 cols=SortBy[Union[support[rows],support[canonTargets]],simpleKey[f,#]&];boundary=sources[{rows,canonTargets}];all=Join[cols,boundary];
 stage["ColumnOrdering"];
 If[solver===Automatic,solver=If[MemberQ[$Packages,"FiniteFlow`"],"FiniteFlow","Exact"]];
 (* Only a fully verified, identical system and ordered column set may be reused.
    Keep one entry in memory; checkpoint rules are never trusted as this cache. *)
 reuse=TrueQ[OptionValue["ReuseVerifiedReduction"]] && MemberQ[{"Exact","FiniteFlow"},solver];
 cacheKey=Hash[{f["Hash"],$implementationHash,rows,all,solver,OptionValue["MaxExactColumns"],OptionValue["MaxPrimes"]},"SHA256"];
 If[reuse && Lookup[$lastVerifiedReduction,"Key",None]===cacheKey,
  If[report=!=None,report[<|"Action"->"Reusing verified full reduction","Rows"->Length[rows],"Columns"->Length[all]|>]];
  Return[reductionTargets[Join[$lastVerifiedReduction["Result"],<|"StageTimings"->timings,"ReductionReused"->True|>],canonTargets,rows]]];
 If[report=!=None,report[<|"Action"->"Starting coefficient solve","Rows"->Length[rows],"Columns"->Length[all],"Solver"->solver|>]];
 If[rows==={},rules={},
  Switch[solver,
   "Exact",If[Length[all]>OptionValue["MaxExactColumns"],Return[fail["ExactSizeLimit","Load FiniteFlow or explicitly increase MaxExactColumns.",<|"Columns"->Length[all]|>]]];
    matrix=coeff[rows,all];reduced=rr[matrix];pivs=pivots[reduced];
    rules=MapThread[all[[#1]]->canonicalLinear[-#2.all+all[[#1]]]&,{pivs,reduced}],
   "FiniteFlow",If[!MemberQ[$Packages,"FiniteFlow`"],Return[fail["FiniteFlowNotLoaded","Call InitializeFiniteFlow or Needs[\"FiniteFlow`\"] first."]]];
    rules=FiniteFlow`FFSparseSolve[#==0& /@ rows,all,"NeededVars"->all,"SparseOutput"->True,"MaxPrimes"->OptionValue["MaxPrimes"]],
   _,If[Head[solver]=!=Function,Return[fail["Solver","Use Exact, FiniteFlow, Automatic, or Function[{equations,columns,queries},rules]."]]];
    rules=solver[rows,all,all]]];
 stage["CoefficientSolve"];
 If[!ListQ[rules] || !And@@(MatchQ[#,_Rule]& /@ rules),Return[fail["SolverFailure","The solver did not return replacement rules."]]];
 (* Keep source constraints already implied by this system. No lower-loop IBP
    generation occurs here; dropping these rules invalidates full residuals. *)
 (* FiniteFlow already returns linear combinations with rational-function
    coefficients. Avoid re-expanding every reconstructed auxiliary rule;
    full exact equation residuals and idempotence are still checked below. *)
 images=If[solver==="FiniteFlow",all/.Dispatch[rules],canonicalLinear /@ (all/.Dispatch[rules])];rules=Thread[all->images];
 stage["NormalizeRules"];
 residual=canonicalLinear /@ (rows/.Dispatch[rules]);
 If[!And@@(zero /@ residual),Return[fail["UnverifiedReduction","Exact residual check failed; no reduction accepted.",<|"Residuals"->DeleteCases[residual,0]|>]]];
 stage["EquationResiduals"];
 raw=Join[support[images],sources[images]];
 If[!And@@(zero /@ (canonicalLinear /@ ((raw/.Dispatch[rules])-raw))),Return[fail["NonIdempotentReduction","Reduction images are not normal forms."]]];
 stage["Idempotence"];
 result=<|"StageTimings"->timings,"ReductionReused"->False,"Rules"->rules,"ReducedTargets"->(canonicalLinear /@ (canonTargets/.Dispatch[rules])),
  "SameLoopRules"->Take[rules,Length[cols]],"BoundaryRules"->Drop[rules,Length[cols]],
  "ColumnOrder"->all,"BoundaryConstraintOrigin"->"Existing input equations only",
  "RawMasters"->support[canonTargets/.Dispatch[rules]],"BoundarySources"->sources[canonTargets/.Dispatch[rules]],
  "SelfReducedTargets"->Select[support[canonTargets],zero[(#/.Dispatch[rules])-#]&],
  "UnseenTargets"->Complement[support[canonTargets],support[rows]],
  "ExactEquationResidualsZero"->True,"Idempotent"->True,"Solver"->solver,
  "Ordering"->Lookup[f,"IntegralOrdering","LadderFirst"],
  "Columns"->Length[all],"EquationCount"->Length[rows]|>;
 If[reuse,$lastVerifiedReduction=<|"Key"->cacheKey,"Result"->result|>];result];

badClusters[f_,g_G]:=With[{a=List@@g},Select[Subsets[Range[f["LoopCount"]],{2,f["LoopCount"]}],
 Function[block,Total[a[[Select[f["LoopLoopIDs"],SubsetQ[block,f["Supports"][[#]]]&]]]]>=2(Length[block]-1)]]];
residueKey[f_,g_,edge_]:=Module[{a=List@@g,pair=f["Supports"][[edge]],ys,keep,p,indices,out,idx,low},
 keep=DeleteCases[Range[f["LoopCount"]],Last[pair]];ys=f["Loops"][[keep]];p=standardProps[f["External"],ys];out=ConstantArray[0,Length[p]];
 a[[edge]]-=2;
 Do[If[j===edge,Continue[]];idx=First[FirstPosition[p,f["Propagators"][[j]]/.f["Loops"][[Last[pair]]]->f["Loops"][[First[pair]]]]];
  out[[idx]]+=a[[j]],{j,Length[f["Propagators"]]}];
 low=CreateFamily[<|"Loops"->ys,"External"->f["External"],"Kinematics"->f["Kinematics"],"Variables"->{},
  "TopSector"->ConstantArray[1,Length[p]],"MaxLoopPower"->Infinity,
  "ExternalPermutations"->f["ExternalPermutations"]|>];
 residueAtom[List@@CanonicalIntegral[low,G@@Join[out,ConstantArray[1,Length[ys]]]]]];
FiniteIntegralQ[f_Association,e_]:=Module[{gs=support[e],bad,rrs=0,a},
 If[sources[e]=!={},Return[False]];
 If[f["FiniteValidator"]=!=Automatic,Return[TrueQ[f["FiniteValidator"][f,e]]]];
 If[FailureQ[canonicalLinear[e]] || !And@@(validIntegral[f,#] && weights[f,List@@#]===ConstantArray[4,f["LoopCount"]]& /@ gs),Return[False]];
 Do[bad=badClusters[f,g];If[bad==={},Continue[]];a=List@@g;
  If[Length[bad]!=1 || Length[First[bad]]!=2,Return[False]];
  With[{edge=First[FirstPosition[f["Supports"],First[bad]]]},If[a[[edge]]=!=2,Return[False]];
   rrs+=Together[Coefficient[Expand[e],g]] residueKey[f,g,edge]],{g,gs}];
 zero[rrs]];

primitive[v_]:=Module[{a=v,d,g},If[!VectorQ[a,MatchQ[#,_Integer|_Rational]&],Return[$Failed]];
 If[And@@(zero /@ a),Return[a]];d=LCM@@(Denominator /@ a);a=d a;g=GCD@@Abs[a];Sign[First[Select[a,#!=0&]]] a/g];
constantAtoms[c_,vars_]:=Module[{atoms={},den,poly,mons},
 Do[den=If[vars==={},LCM@@(Denominator /@ row),PolynomialLCM@@(Denominator /@ row)];
  poly=Expand[Cancel[den #]]& /@ row;
  If[vars==={},AppendTo[atoms,poly],
   If[!And@@(PolynomialQ[#,vars]& /@ poly),Return[$Failed]];
   mons=Union[Flatten[First /@ CoefficientRules[#,vars]& /@ poly,1]];
   Do[AppendTo[atoms,Fold[Coefficient[#1,First[#2],Last[#2]]&,#,Transpose[{vars,mon}]]& /@ poly],{mon,mons}]],{row,c}];
 atoms];
BuildFiniteBasis[f_Association,rows_List]:=Module[{gs=support[rows],safe,div,c,atoms,env,p,inside,pool,chosen={},ranks={},trial,v,rank,
 basis,m,bp,w,residue,den,definitions},
 safe=Select[gs,FiniteIntegralQ[f,#]&];div=Complement[gs,safe];c=coeff[rows,div];
 If[div==={},basis=safe;rank=0;chosen={},
  If[!And@@(zero[Total[#]]& /@ c),Return[fail["NoConstantZeroSumCover","Divergent coefficient sums are nonzero; additional relations/ordering are needed."]]];
  atoms=constantAtoms[c,f["Variables"]];If[atoms===$Failed,Return[fail["NonRationalCoefficients","Coefficient extraction requires rational kinematic functions."]]];
  env=rr[atoms];p=pivots[env];rank=Length[env];
  inside[v_]:=And@@(zero /@ (v-v[[p]].env));
  pool=Join[Select[(UnitVector[Length[div],#[[1]]]-UnitVector[Length[div],#[[2]]]& /@ Subsets[Range[Length[div]],{2}]),inside],primitive /@ env];
  pool=SortBy[DeleteDuplicates[pool],{Count[#,Except[0]]&,Total[Abs[#]]&,Identity}];
  Do[If[FiniteIntegralQ[f,v.div] && Length[rr[Append[chosen,v]]]>Length[chosen],AppendTo[chosen,v]],{v,pool}];
  If[Length[chosen]!=rank,Return[fail["UnverifiedFiniteCover","Actual coefficient blocks cannot all be certified finite; they will not be differentiated.",<|"RequiredRank"->rank,"CertifiedRank"->Length[chosen]|>]]];
  basis=Join[safe,(#.div& /@ chosen)]];
 m=coeff[basis,gs];bp=pivots[rr[m]];
 w=If[basis==={},ConstantArray[{},Length[rows]],Map[Together,coeff[rows,gs][[All,bp]].Inverse[m[[All,bp]]],{2}]];
 residue=canonicalLinear /@ (rows-w.basis);residue=residue/._BoundaryIntegral->0;
 If[!And@@(zero /@ residue),Return[fail["FiniteReconstruction","Finite basis does not cover the entire input/DE."]]];
 <|"Basis"->basis,"SingleFinite"->safe,"Combinations"->(#.div& /@ chosen),"Weights"->w,
  "BoundaryRows"->(rows/._G->0),"ConstantCombinationRank"->rank,
  "MinimumCountForActualConstantSpan"->True,"GlobalSparsityOptimumClaimed"->False,
  "ExactCoverage"->True,"NoKinematicsInCombinations"->FreeQ[chosen,Alternatives@@f["Variables"]],
  "FinitenessCriterion"->"Conformal scaling and isolated double-collision residues modulo exact symmetries; overlapping clusters require a custom validator"|>];
