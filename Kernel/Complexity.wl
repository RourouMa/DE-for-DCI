(* Complexity is a diagnostic of incomplete reduction / poor representatives, never a relation. *)
IntegralComplexity[f_Association,g_G]:=Module[{a,p,n,joint},
 If[!validIntegral[f,g],Return[fail["IntegralShape","Malformed integral in complexity audit."]]];
 a=Take[List@@g,Length[f["Propagators"]]];p=Select[a,Positive];n=-Select[a,Negative];
 joint=Min[Total[n],Total[p]-Length[p]];
 <|"Integral"->g,"Sector"->Flatten[Position[a,_?Positive]],"PropagatorCount"->Length[p],
 "PositiveDegree"->Total[p],"NumeratorDegree"->Total[n],"Dots"->Total[p]-Length[p],
 "MaxDenominatorPower"->Max[Append[p,0]],"MaxNumeratorPower"->Max[Append[n,0]],
 "JointExcess"->joint,"GrowthLevel"->Which[joint<=1,"Routine",joint===2,"UncommonSecondOrder",True,"StrongHigherOrderSignal"],
 "GrowthReference"->"Numerator degree and dots relative to zero numerator and unit positive powers; topology-specific baselines must also be considered",
 "Score"->{Total[n]+Total[p]-Length[p],Max[Append[p,0]],Max[Append[n,0]]},
 "LoopWeights"->weights[f,List@@g],"Components"->parts[f,g],"UnitCutsExcluded"->True|>];
complexityFlag[p_Association]:=p["NumeratorDegree"]>=3 && p["Dots"]>=3;
Options[AssessBasisComplexity]={"EquationPoolHash"->None,"SectorProfiles"->{}};
AssessBasisComplexity[f_Association,basis_List,reduction_Association,OptionsPattern[]]:=Module[
 {atoms=support[basis],profiles,known=Association[Lookup[reduction,"Rules",{}]],sectorProfiles=OptionValue["SectorProfiles"],suspect,aboveReference,records,flagged,nfTargets,unqueried,physical,flaggedAtoms,canonicalAtoms},
 If[!AllTrue[atoms,validIntegral[f,#]&],Return[fail["IntegralShape","Malformed basis in complexity audit."]]];
 If[!ListQ[sectorProfiles] || !AllTrue[sectorProfiles,AssociationQ[#] &&
   Lookup[#,"FamilyHash",None]===f["Hash"] && ListQ[Lookup[#,"Sector",None]] &&
   MatchQ[Lookup[#,"Score",None],{_Integer,_Integer,_Integer}] &&
   StringQ[Lookup[#,"Evidence",None]] && StringLength[StringTrim[#["Evidence"]]]>0&],
  Return[fail["ComplexityProfiles","Sector profiles require the same family hash, sector, score and recorded evidence."]]];
 suspect[g_G]:=complexityFlag[IntegralComplexity[f,g]];
 aboveReference[g_G]:=With[{p=IntegralComplexity[f,g]},
   AnyTrue[sectorProfiles,#["Sector"]===p["Sector"] && #["Score"]=!=p["Score"] && OrderedQ[{#["Score"],p["Score"]}]&]];
 profiles=IntegralComplexity[f,#]& /@ atoms;
 canonicalAtoms=CanonicalIntegral[f,#]& /@ atoms;
 If[AnyTrue[canonicalAtoms,FailureQ],Return[First[Select[canonicalAtoms,FailureQ]]]];
 records=Table[Module[{g=atoms[[k]],cg=canonicalAtoms[[k]],nf,hard,seen},
  seen=KeyExistsQ[known,cg];nf=If[seen,known[cg],cg];
  hard=Select[support[nf],suspect];
  Join[IntegralComplexity[f,g],<|"Canonical"->cg,"Flagged"->suspect[g],"Queried"->seen,
   "AboveRecordedSectorReference"->aboveReference[g],
   "SelfReduced"->(seen && cg===nf),"NormalForm"->nf,"ComplexNormalFormAtoms"->hard,
   "Classification"->Which[!seen,"QueryBeforeJudging",hard=!={},"TargetedRelationAudit",suspect[g],"ReplaceComplexRepresentative",True,"NoComplexitySignal"]|>]],{k,Length[atoms]}];
 If[AnyTrue[records,FailureQ],Return[First[Select[records,FailureQ]]]];
 flagged=Select[records,TrueQ[#["Flagged"]] || #["ComplexNormalFormAtoms"]=!={}&];
 nfTargets=Union[Flatten[Lookup[flagged,"ComplexNormalFormAtoms",{}]]];
 unqueried=Lookup[Select[flagged,!TrueQ[#["Queried"]]&],"Canonical",{}];
 flaggedAtoms=Lookup[flagged,"Integral",{}];
 physical=MapIndexed[Function[{expr,index},Module[{aa=support[expr],finite,div},
  finite=TrueQ[FiniteIntegralQ[f,expr]];div=Select[aa,!TrueQ[FiniteIntegralQ[f,#]]&];
  <|"Index"->First[index],"Expression"->expr,"Atoms"->aa,"FiniteAsWhole"->finite,
   "DivergentAtoms"->div,"RequiresComplexityReview"->(Intersection[aa,flaggedAtoms]=!={}),
   "CoverageSearchTarget"->expr,"CoverageSearchUnit"->"WholeExpression",
   "AtomwiseFiniteCoverageRequired"->False,
   "Interpretation"->If[finite&&div=!={},"Divergent atoms belong to a certified finite combination; test coverage of the whole combination","Compare complete candidate with simpler finite representatives"]|>]],basis];
 <|"FamilyHash"->f["Hash"],"BasisHash"->Hash[basis,"SHA256"],"EquationPoolHash"->OptionValue["EquationPoolHash"],
 "Profiles"->profiles,"Records"->records,"FlaggedCount"->Length[flagged],"RequiresReview"->(flagged=!={}),
 "PhysicalCandidates"->physical,"AuditedCandidateCount"->Length[basis],
 "GrowthLevelCounts"->Counts[Lookup[profiles,"GrowthLevel"]],
 "SecondOrderGrowthAloneBlocksAdvancement"->False,"AboveReferenceAloneProvesReducibility"->False,
 "SimplerRepresentativeSearchTargets"->Lookup[Select[physical,TrueQ[#["RequiresComplexityReview"]]&],"Expression",{}],
 "RepresentativeSearchScope"->"All actually occurring allowed sectors, including symmetry-related subtopologies; not only the flagged atom's positive sector",
 "RepresentativeReplacementTargets"->Lookup[Select[flagged,#["Classification"]==="ReplaceComplexRepresentative"&],"Canonical",{}],
 "TargetedSeedTargets"->Union[nfTargets,unqueried],"SectorProfiles"->sectorProfiles,
 "ComplexityProvesReducibility"->False,"OutputCountIsMasterCount"->False,
 "NextAction"->Which[unqueried=!={},"Query flagged candidates in the existing pool before generating equations",nfTargets=!={},"Compare whole finite candidates with simpler representatives across actual allowed sectors before targeting missing relations",flagged=!={},"Select a simpler finite representative using existing reductions",True,"Proceed with independently certified finite coverage"]|>];
complexityDecisionQ[a_,d_]:=AssociationQ[d] && And@@(Lookup[d,#,Missing[]]===a[#]& /@
 {"FamilyHash","BasisHash","EquationPoolHash"}) &&
 AllTrue[{"Reason","TargetedSeedAudit","SymmetryAudit","SimplerBasisComparison"},
 StringQ[Lookup[d,#,None]] && StringLength[StringTrim[Lookup[d,#,""]]]>0&];
complexityAdvanceContract[a_,decision_]:=If[FailureQ[a],a,
 If[!TrueQ[a["RequiresReview"]] || complexityDecisionQ[a,decision],a,
 fail["ComplexityReviewRequired","Finite coverage alone does not justify differentiating suspiciously complex representatives. Resolve the recorded audit or supply evidence tied to this family, basis and equation pool.",<|"Audit"->a|>]]];

(* Enumerate exact preimages of ordinary operator shifts, not a Cartesian power box.
   A nonzero ordinary coefficient is only a planner filter; IBPRelation still certifies contacts. *)
inverseSeedBatches[f_,centers_,operators_,seedDomain_]:=Module[{n=Length[f["Propagators"]],records,op,template,shifts,seeds},
 records=Table[op=operators[[k]];template=ordinaryShiftTemplate[f["Hash"],f,op];
  shifts=Union[Flatten[(First /@ #)& /@ template,1]];
  seeds=Union[Flatten[Table[G@@Join[Take[List@@g,n]-shift,ConstantArray[1,f["LoopCount"]]],{g,centers},{shift,shifts}],1]];
  seeds=Select[seeds,domainQ[f,#] && (seedDomain==="Extended" || originalDomainIntegralQ[f,#]) &&
   weights[f,List@@#]+op["Degree"]===ConstantArray[4,f["LoopCount"]]&];
  seeds=Select[seeds,Function[seed,With[{action=Expand[ordinaryShiftAction[f,op,seed]]},AnyTrue[centers,!zero[Coefficient[action,#]]&]]]];
  <|"OperatorIndex"->k,"Degree"->op["Degree"],"Seeds"->seeds|>,{k,Length[operators]}];records];
