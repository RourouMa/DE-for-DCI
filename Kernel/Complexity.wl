(* Complexity guides relation searches; basis policy is explicit and never changed by this audit. *)
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
Options[AssessBasisComplexity]={"EquationPoolHash"->None,"SectorProfiles"->{},"FiniteBasisPolicy"->"StrictOrdering"};
AssessBasisComplexity[f_Association,basis_List,reduction_Association,OptionsPattern[]]:=Module[
 {atoms=support[basis],profiles,known=Association[Lookup[reduction,"Rules",{}]],sectorProfiles=OptionValue["SectorProfiles"],suspect,aboveReference,records,flagged,nfTargets,unqueried,physical,flaggedAtoms,canonicalAtoms,policy=OptionValue["FiniteBasisPolicy"]},
 If[!MemberQ[{"StrictOrdering","PreserveActualSpan","FiniteSupportThenSpan"},policy],Return[fail["FiniteBasisPolicy","Unknown finite-cover policy."]]];
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
   "Interpretation"->If[finite&&div=!={},"Divergent atoms belong to a certified finite combination; test coverage of the whole combination","Reduce the complete candidate under the specified ordering and inspect surviving atoms"]|>]],basis];
 <|"FamilyHash"->f["Hash"],"BasisHash"->Hash[basis,"SHA256"],"EquationPoolHash"->OptionValue["EquationPoolHash"],
 "Profiles"->profiles,"Records"->records,"FlaggedCount"->Length[flagged],"RequiresReview"->(flagged=!={}),
 "PhysicalCandidates"->physical,"AuditedCandidateCount"->Length[basis],
 "GrowthLevelCounts"->Counts[Lookup[profiles,"GrowthLevel"]],
 "SecondOrderGrowthAloneBlocksAdvancement"->False,"AboveReferenceAloneProvesReducibility"->False,
 "SimplerRepresentativeSearchTargets"->Lookup[Select[physical,TrueQ[#["RequiresComplexityReview"]]&],"Expression",{}],
 "FiniteBasisPolicy"->policy,
 "RepresentativeSearchScope"->Switch[policy,"StrictOrdering","Surviving ordered atoms in actually allowed sectors","FiniteSupportThenSpan","Retain all finite normal-form atoms; with divergent support, verify finite representatives inside the actual rational span",_,"Verified finite representatives inside the actual rational span in actually allowed sectors"],
 "OrderingPreferenceMustBePreserved"->(policy==="StrictOrdering"),"ReintroducingEliminatedQueriesAllowed"->(policy=!="StrictOrdering"),
 "RepresentativeReplacementTargets"->Lookup[Select[flagged,#["Classification"]==="ReplaceComplexRepresentative"&],"Canonical",{}],
 "TargetedSeedTargets"->Union[nfTargets,unqueried],"SectorProfiles"->sectorProfiles,
 "ComplexityProvesReducibility"->False,"OutputCountIsMasterCount"->False,
 "NextAction"->Which[unqueried=!={},"Query flagged candidates in the existing pool under the specified ordering before generating equations",nfTargets=!={},"Audit missing IBP and matching supersector symmetry for complex survivors; retain ordering and replay top after pool expansion",flagged=!={},If[policy==="StrictOrdering","Use the existing ordered normal form; do not invert reductions to reintroduce eliminated queries","Compare simpler representatives using verified reduction, membership and exact coverage"],True,"Proceed with certified finite coverage under the declared basis policy"]|>];
complexityDecisionQ[a_,d_]:=AssociationQ[d] && And@@(Lookup[d,#,Missing[]]===a[#]& /@
 {"FamilyHash","BasisHash","EquationPoolHash"}) &&
 AllTrue[{"Reason","TargetedSeedAudit","SymmetryAudit","SimplerBasisComparison"},
 StringQ[Lookup[d,#,None]] && StringLength[StringTrim[Lookup[d,#,""]]]>0&];
complexityAdvanceContract[a_,decision_]:=If[FailureQ[a],a,
 If[!TrueQ[a["RequiresReview"]] || complexityDecisionQ[a,decision],a,
 fail["ComplexityReviewRequired","Finite coverage alone does not justify differentiating suspiciously complex representatives. Resolve the recorded audit or supply evidence tied to this family, basis and equation pool.",<|"Audit"->a|>]]];

(* Enumerate exact preimages of ordinary operator shifts, not a Cartesian power box.
   A nonzero ordinary coefficient is only a planner filter; IBPRelation still certifies contacts. *)
inverseSeedBatches[f_,centers_,operators_,seedDomain_,operatorPolicy_:"Complete"]:=Module[{n=Length[f["Propagators"]],records,op,template,shifts,seeds,selected},
 records=Table[op=operators[[k]];template=ordinaryShiftTemplate[f["Hash"],f,op];
  shifts=Union[Flatten[(First /@ #)& /@ template,1]];
  seeds=Union[Flatten[Table[G@@Join[Take[List@@g,n]-shift,ConstantArray[1,f["LoopCount"]]],{g,centers},{shift,shifts}],1]];
  seeds=Select[seeds,domainQ[f,#] && (seedDomain==="Extended" || originalDomainIntegralQ[f,#]) &&
   weights[f,List@@#]+op["Degree"]===ConstantArray[4,f["LoopCount"]]&];
  seeds=Select[seeds,Function[seed,With[{action=Expand[ordinaryShiftAction[f,op,seed]]},AnyTrue[centers,!zero[Coefficient[action,#]]&]]]];
  <|"OperatorIndex"->k,"Degree"->op["Degree"],"Seeds"->seeds|>,{k,Length[operators]}];
 If[operatorPolicy==="DirectHit",Return[records]];
 selected=Union[Flatten[Lookup[records,"Seeds",{}],1]];
 Table[op=operators[[k]];<|"OperatorIndex"->k,"Degree"->op["Degree"],"Seeds"->Select[selected,weights[f,List@@#]+op["Degree"]===ConstantArray[4,f["LoopCount"]]&]|>,{k,Length[operators]}]];
