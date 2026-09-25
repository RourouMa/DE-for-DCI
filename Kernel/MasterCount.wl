(* Geometric counts are kept separate from their applicability to a physical
   integral space. No observed DE dimension is used by this module. *)
Options[CriticalPointCount]={"Method"->"Proper","LogWeights"->Automatic,
 "PermutationSymmetries"->{},"Modulus"->0,"TimeLimit"->300,"MaxQuotientDimension"->100000};

criticalSymmetryDimension[p_,xs_,gb_,vs_,exponents_,generators_,mod_]:=Module[
 {group,monomials,traces,images,nf,cr,trace,count,n=Length[exponents]},
 If[generators==={},Return[<|"GroupOrder"->1,"InvariantDimension"->n,"Traces"->{n}|>]];
 If[!ListQ[generators]||!AllTrue[generators,ListQ[#]&&Sort[#]===Range[Length[xs]]&],
  Return[fail["CriticalSymmetry","Symmetries must be permutations of the polynomial variables."]]];
 group=permutationClosure[generators,Length[xs]];
 If[mod=!=0&&Mod[Length[group],mod]===0,Return[fail["CriticalSymmetryCharacteristic","The characteristic divides the symmetry group order."]]];
 If[!AllTrue[group,zero[p-(p/.Thread[xs->xs[[#]]])]&],Return[fail["CriticalSymmetry","A proposed permutation does not preserve the counting polynomial at the declared kinematics."]]];
 monomials=(Times@@(vs^#)& /@ exponents);
 traces=Table[images=monomials/.Thread[xs->xs[[perm]]];
  trace=Sum[nf=Last[PolynomialReduce[images[[k]],gb,vs,MonomialOrder->DegreeReverseLexicographic,
    CoefficientDomain->RationalFunctions,Modulus->mod]];
   cr=Association[CoefficientRules[nf,vs]];Lookup[cr,Key[exponents[[k]]],0],{k,n}];Together[trace],{perm,group}];
 count=If[mod===0,Together[Total[traces]/Length[group]],Mod[Total[traces] PowerMod[Length[group],-1,mod],mod]];
 If[!IntegerQ[count]||count<0||count>n||(mod=!=0&&mod<=n),Return[fail["CriticalSymmetryTrace","The trace projector did not yield an unambiguous invariant dimension.",<|"Traces"->traces,"RawDimension"->n|>]]];
 <|"GroupOrder"->Length[group],"Permutations"->group,"Traces"->traces,"InvariantDimension"->count,
  "Method"->"Trace of the finite-group averaging projector on the saturated quotient"|>];

criticalStaircase[gb_List,vs_List,limit_Integer]:=Module[{lead,n=Length[vs],units,basis,seen,head=1,e,next,key},
 If[AnyTrue[gb,FreeQ[#,Alternatives@@vs]&&!zero[#]&],Return[<|"Dimension"->0,"Exponents"->{}|>]];
 lead=DeleteDuplicates[(Exponent[First[MonomialList[#,vs,DegreeReverseLexicographic]],vs]& /@ DeleteCases[gb,0])];
 units=IdentityMatrix[n];
 If[!And@@Table[AnyTrue[lead,#[[i]]>0&&Total[Delete[#,i]]===0&],{i,n}],
  Return[fail["NonIsolatedCriticalLocus","The saturated critical ideal is positive dimensional; a finite isolated-point count is not available.",<|"LeadingExponents"->lead|>]]];
 basis={ConstantArray[0,n]};seen=<|ToString[First[basis],InputForm]->True|>;
 While[head<=Length[basis],e=basis[[head++]];
  Do[next=e+u;key=ToString[next,InputForm];
   If[!KeyExistsQ[seen,key],AssociateTo[seen,key->True];
    If[!AnyTrue[lead,And@@Thread[#<=next]&],AppendTo[basis,next]]],{u,units}];
  If[Length[basis]>limit,Return[fail["QuotientDimensionLimit","The standard-monomial enumeration exceeded its resource limit; no truncated count is returned.",<|"Limit"->limit|>]]]];
 <|"Dimension"->Length[basis],"Exponents"->basis,"LeadingExponents"->lead|>];

CriticalPointCount[poly_,xs_List,OptionsPattern[]]:=Module[
 {p=Expand[poly],method=OptionValue["Method"],mod=OptionValue["Modulus"],time=OptionValue["TimeLimit"],
  limit=OptionValue["MaxQuotientDimension"],weights=OptionValue["LogWeights"],sym=OptionValue["PermutationSymmetries"],symCount,s,vs,eq,open,gb,stair,t0=AbsoluteTime[],params,genericWeights=False,status},
 If[!VectorQ[xs,MatchQ[#,_Symbol]&]||!DuplicateFreeQ[xs]||!PolynomialQ[p,xs]||!FreeQ[p,_Real],
  Return[fail["CriticalPolynomial","Use a polynomial in distinct symbolic variables with exact coefficients."]]];
 If[!MemberQ[{"Proper","Euler"},method]||!(mod===0||(IntegerQ[mod]&&PrimeQ[mod]))||
  !(time===Infinity||(NumericQ[time]&&time>0))||!IntegerQ[limit]||limit<1,
  Return[fail["CriticalOptions","Invalid counting method, prime, time limit or quotient dimension limit."]]];
 If[method==="Euler",
  If[sym=!={},Return[fail["EulerSymmetryScope","Independent logarithmic weights are not a fixed symmetry-invariant coefficient field. Compute proper-sector symmetry counts separately."]]];
  genericWeights=weights===Automatic;
  If[genericWeights,weights=Table[Unique["logWeight$"],{Length[xs]}]];
  If[!ListQ[weights]||Length[weights]=!=Length[xs]||!FreeQ[weights,_Real]||!FreeQ[weights,Alternatives@@xs],
   Return[fail["LogWeights","Supply one exact weight independent of the integration variables, or Automatic for algebraically independent weights."]]]];
 params=Complement[Union[Cases[p,q_Symbol/;Context[q]=!="System`",Infinity]],xs];
 s=Unique["criticalSaturation$"];vs=Prepend[xs,s];
 open=If[method==="Proper",p,Expand[p Times@@xs]];
 eq=If[method==="Proper",D[p,#]& /@ xs,MapThread[Expand[#1 D[p,#1]-#2 p]&,{xs,weights}]];
 eq=Append[eq,s open-1];
 gb=TimeConstrained[Quiet[Check[GroebnerBasis[eq,vs,MonomialOrder->DegreeReverseLexicographic,
   CoefficientDomain->RationalFunctions,Modulus->mod],$Failed]],time,$Aborted];
 If[gb===$Aborted,Return[fail["CriticalCountTimeout","Critical-point Groebner computation timed out; no count is inferred.",<|"Seconds"->time,"Polynomial"->p,"Variables"->xs,"Method"->method|>]]];
 If[!ListQ[gb]||!And@@(PolynomialQ[#,vs]& /@ gb),Return[fail["CriticalGroebnerFailure","The exact polynomial computation did not return a Groebner basis."]]];
 stair=criticalStaircase[gb,vs,limit];If[FailureQ[stair],Return[stair]];
 symCount=criticalSymmetryDimension[p,xs,gb,vs,stair["Exponents"],sym,mod];If[FailureQ[symCount],Return[symCount]];
 status=Which[mod=!=0,"FiniteFieldCount",method==="Euler"&&genericWeights,"ExactGenericEulerCharacteristic",
  method==="Euler","SpecializedLogarithmicCount",True,"ExactProperCriticalMultiplicity"];
 <|"Status"->status,"Count"->stair["Dimension"],"MultiplicityIncluded"->True,"Method"->method,
  "CountAfterSymmetry"->symCount["InvariantDimension"],"Symmetry"->symCount,
  "Polynomial"->p,"Variables"->xs,"CoefficientParameters"->params,"Characteristic"->mod,
  "LogWeights"->If[method==="Euler",weights,None],"GenericLogWeights"->genericWeights,
  "SaturationPolynomial"->open,"IdealGenerators"->eq,"GroebnerVariables"->vs,
  "GroebnerBasis"->gb,"StandardMonomialExponents"->stair["Exponents"],
  "MonomialOrder"->DegreeReverseLexicographic,"Seconds"->AbsoluteTime[]-t0,
  "IsMasterIntegralUpperBound"->False,
  "InfinityTreatment"->If[method==="Euler"&&genericWeights,"VeryAffineEulerCharacteristic","NotCertified"],
  "Reference"->If[method==="Euler","https://arxiv.org/abs/1207.0553","https://arxiv.org/abs/1308.6676"]|>];

(* Affine chart of the null projective loop cone, with X_a.I=1.
   2 SP[X_a,Y_i]=(q_i-p_a)^2+m_a^2, m_a^2=SP[X_a,X_a].
   p_last=0. This constructs an ordinary dimensionally continued reference
   representation. Its count is NOT automatically the strict-D=4 DCI count. *)
ParametricRepresentation[f_Association,sector_List]:=Module[
 {l=f["LoopCount"],e=Length[f["External"]],gram=f["Gram"],props=f["Propagators"],z,a,b,c=0,h,adj,u,ff,q,ids,i,j,k,ext,loops},
 If[familyHash[f]=!=f["Hash"]||!VectorQ[sector,IntegerQ]||!DuplicateFreeQ[sector]||Complement[sector,Range[Length[props]]]=!={},
  Return[fail["CountSector","Supply distinct ordinary propagator IDs in a valid family; unit cuts are not Schwinger parameters."]]];
 ids=Sort[sector];z=Table[Unique["schwinger$"],{Length[ids]}];
 a=ConstantArray[0,{l,l}];b=ConstantArray[0,{l,Max[0,e-1]}];
 h=Table[gram[[i,e]]+gram[[j,e]]-gram[[i,j]]-gram[[e,e]],{i,e-1},{j,e-1}];
 Do[q=props[[ids[[k]]]];ext=Intersection[List@@q,f["External"]];loops=Intersection[List@@q,f["Loops"]];
  i=First[FirstPosition[f["Loops"],First[loops]]];
  If[Length[ext]===1,j=First[FirstPosition[f["External"],First[ext]]];a[[i,i]]+=z[[k]];
   c+=z[[k]](2 gram[[j,e]]-gram[[e,e]]);If[j<e,b[[i,j]]-=z[[k]]],
   j=First[FirstPosition[f["Loops"],Last[loops]]];
   a[[i,i]]+=z[[k]];a[[j,j]]+=z[[k]];a[[i,j]]-=z[[k]];a[[j,i]]-=z[[k]]],{k,Length[ids]}];
 u=Expand[Det[a]];
 adj=If[l===1,{{1}},Table[(-1)^(i+j)Det[Map[Delete[#,i]&,Delete[a,j]]],{i,l},{j,l}]];
 ff=Expand[u c-Tr[adj.b.h.Transpose[b]]];
 <|"Representation"->"OrdinaryAffineChartReference","FamilyHash"->f["Hash"],"Sector"->ids,
  "Parameters"->z,"U"->u,"F"->ff,"Polynomial"->Expand[u+ff],"QuadraticMatrix"->a,
  "LinearMatrix"->b,"Constant"->c,"ExternalPositionGram"->h,"Dimension"->"Generic",
  "CutsIntegratedAsNullProjectiveCone"->True,"StrictFourDimensionalApplicability"->"Unverified",
  "SymmetryQuotiented"->False,"LowerLoopContactsIncluded"->False|>];

(* Only exact global relabelings at the declared kinematics are used here.
   Independent component relabelings need numerator/factorization information
   and cannot be inferred just by omitting a positive loop-loop denominator. *)
masterCountPropagatorMaps[f_]:=masterCountPropagatorMaps[f]=Module[{p=f["Propagators"]},
 DeleteDuplicates[Flatten[Table[
   (First[FirstPosition[p,#]]& /@ (p/.Join[Thread[f["External"]->f["External"][[ep]]],Thread[f["Loops"]->f["Loops"][[lp]]]])),
   {ep,f["ExternalPermutations"]},{lp,Permutations[Range[f["LoopCount"]]]}],1]]];
masterCountSectorOrbits[f_,sectors_List]:=Module[{maps=masterCountPropagatorMaps[f],key},
 key[sec_]:=First[Sort[Sort[#[[sec]]]& /@ maps]];
 SortBy[GatherBy[sectors,key],First]];
masterCountSectorStabilizer[f_,sec_List]:=DeleteDuplicates[
 (First[FirstPosition[sec,#]]& /@ #[[sec]]& /@ Select[masterCountPropagatorMaps[f],Sort[#[[sec]]]===sec&])];

Options[MasterIntegralCount]={"Sectors"->Automatic,"IncludeSubsectors"->True,"SectorSymmetry"->True,
 "Method"->"Proper","LogWeights"->Automatic,"Modulus"->0,"TimeLimit"->300,"TotalTimeLimit"->60,"MaxQuotientDimension"->100000,
 "ProgressFunction"->Print};
MasterIntegralCount[f_Association,inputs_List,OptionsPattern[]]:=Module[
 {sectors=OptionValue["Sectors"],sub=OptionValue["IncludeSubsectors"],sym=OptionValue["SectorSymmetry"],results={},rep,count,method=OptionValue["Method"],opts,event,complete,orbits,allSectors,started=AbsoluteTime[],totalTime=OptionValue["TotalTimeLimit"],remaining},
 If[!(totalTime===Infinity||(NumericQ[totalTime]&&totalTime>0)),Return[fail["CountTimeLimit","TotalTimeLimit must be positive or Infinity."]]];
 If[!MemberQ[{True,False},sub]||!MemberQ[{True,False},sym]||!And@@(validIntegral[f,#]& /@ support[inputs]),Return[fail["CountInputs","Invalid integral inputs, symmetry or subsector option."]]];
 If[sectors===Automatic,sectors=DeleteDuplicates[(Flatten[Position[Take[List@@#,Length[f["Propagators"]]],_?Positive]]& /@ support[inputs])]];
 If[!ListQ[sectors]||!And@@(ListQ[#]&&VectorQ[#,IntegerQ]&&DuplicateFreeQ[#]&&Complement[#,Range[Length[f["Propagators"]]]]==={}& /@ sectors),Return[fail["CountSectors","Sectors must be lists of ordinary propagator IDs."]]];
 If[method==="Euler"&&sub,Return[fail["EulerScope","A torus Euler count and a sum of proper sector counts have different scopes. Use IncludeSubsectors->False with Method->Euler."]]];
 sectors=Union[Sort /@ If[sub,Flatten[Subsets /@ sectors,1],sectors]];
 allSectors=sectors;orbits=If[sym,masterCountSectorOrbits[f,sectors],List /@ sectors];sectors=First /@ orbits;
 opts=FilterRules[{"Method"->method,"LogWeights"->OptionValue["LogWeights"],"Modulus"->OptionValue["Modulus"],
  "TimeLimit"->OptionValue["TimeLimit"],"MaxQuotientDimension"->OptionValue["MaxQuotientDimension"]},Options[CriticalPointCount]];
 Do[remaining=totalTime-(AbsoluteTime[]-started);If[remaining<=0,Break[]];rep=ParametricRepresentation[f,sec];
  count=If[FailureQ[rep],rep,TimeConstrained[CriticalPointCount[rep["Polynomial"],rep["Parameters"],
   "PermutationSymmetries"->If[sym&&method==="Proper",masterCountSectorStabilizer[f,sec],{}],Sequence@@opts],remaining,
    fail["MasterCountTotalTimeout","The total counting budget expired; this sector was not counted."]]];
  AppendTo[results,<|"Sector"->sec,"Representation"->rep,"CriticalCount"->count|>];
  event=<|"Event"->"MasterCountSector","Completed"->Length[results],"Total"->Length[sectors],"Sector"->sec,
  "Count"->If[FailureQ[count],Missing["Unavailable"],count["CountAfterSymmetry"]],"Status"->If[FailureQ[count],count[[1]],count["Status"]]|>;
  If[OptionValue["ProgressFunction"]=!=None,OptionValue["ProgressFunction"][event]],{sec,sectors}];
 complete=Length[results]===Length[sectors]&&AllTrue[results,AssociationQ[#["CriticalCount"]]&];
 <|"Status"->If[complete,"ReferenceEstimate","Incomplete"],"FamilyHash"->f["Hash"],"InputHash"->Hash[inputs,"SHA256"],
  "Count"->If[complete,Total[(#["CriticalCount"]["CountAfterSymmetry"]& /@ results)],Missing["IncompleteCount"]],
  "CertifiedUpperBound"->Missing["ApplicabilityNotCertified"],"Scope"->"OrdinaryGenericDimensionReference",
  "IncludeSubsectors"->sub,"Method"->method,"SectorResults"->results,"SectorOrbits"->orbits,
  "LoopCount"->f["LoopCount"],"CountedLoopScope"->"Same-loop ordinary reference sectors; lower-loop contact spaces require separate counts",
  "UncomputedSectors"->Drop[sectors,Length[results]],"Seconds"->AbsoluteTime[]-started,
  "OriginalSectorCount"->Length[allSectors],"RepresentativeSectorCount"->Length[sectors],
  "UnquotientedReferenceCount"->If[complete,Total[MapThread[#1["CriticalCount"]["Count"] Length[#2]&,{results,orbits}]],Missing["IncompleteCount"]],
  "SectorOrbitReferenceCount"->If[complete,Total[(#["CriticalCount"]["Count"]& /@ results)],Missing["IncompleteCount"]],
  "SectorSymmetryQuotiented"->sym,"WithinSectorSymmetryQuotiented"->(sym&&method==="Proper"),"SymmetryQuotiented"->sym,
  "LowerLoopContactsIncluded"->False,"IsMasterIntegralUpperBound"->False,
  "OutstandingChecks"->{"Strict four-dimensional specialization and projective weights","Contact-source scope",If[method==="Proper","Nonisolated loci and possible contributions at infinity","Integer-index specialization"]}|>];

(* Geometry/TopAnnihilator require certification in Required mode. Explicit
   UserEstimate instead supplies an operational threshold, never a certificate. *)
masterCountPreflight[s_Association]:=Module[{o=s["Options"],mode,strategy,result,started=AbsoluteTime[],opts,results,certified,bound,allowed},
 mode=Lookup[o,"MasterCountPreflight","Advisory"];
 If[!MemberQ[{"Required","Advisory","Disabled"},mode],Return[fail["MasterCountPolicy","Use Required, Advisory or an explicitly justified Disabled preflight."]]];
 If[mode==="Disabled",
  If[!StringQ[Lookup[o,"MasterCountReason",None]]||StringLength[StringTrim[o["MasterCountReason"]]]===0,
   Return[fail["MasterCountReason","Disabling geometric preflight requires a recorded reason."]]];
  Return[<|"Status"->"Disabled","Reason"->o["MasterCountReason"],"CanStartDE"->True,"IsMasterIntegralUpperBound"->False|>]];
 opts=Lookup[o,"MasterCountOptions",{}];
 strategy=Lookup[o,"MasterCountStrategy","Geometry"];
 If[!MemberQ[{"TopAnnihilator","Geometry","UserEstimate"},strategy],Return[fail["MasterCountStrategy","Choose TopAnnihilator, Geometry or UserEstimate."]]];
 If[strategy==="UserEstimate",
  bound=Lookup[o,"MasterCountUserUpperBound",Automatic];
  If[!IntegerQ[bound] || bound<1,Return[fail["MasterCountUserUpperBound","UserEstimate requires a positive integer MasterCountUserUpperBound."]]];
  If[opts=!={},Return[fail["MasterCountOptions","UserEstimate takes MasterCountUserUpperBound directly; geometric counting options do not apply."]]];
  Return[<|"Status"->"UserEstimatedUpperBound","Scope"->"HighestLoopModuloBoundary","BoundSpace"->"SameLoopFamily",
   "LoopCount"->s["Family"]["LoopCount"],"FamilyHash"->s["Family"]["Hash"],
   "UserEstimatedUpperBound"->bound,"StoppingThreshold"->bound,"HasStoppingThreshold"->True,"ThresholdOrigin"->"UserEstimate",
   "LoopUpperBounds"->Association@Table[k->If[k===s["Family"]["LoopCount"],bound,Missing["SeparateCountRequired"]],{k,s["Family"]["LoopCount"],1,-1}],
   "CertifiedUpperBound"->Missing["UserEstimateNotCertified"],"IsMasterIntegralUpperBound"->False,
   "Reason"->Replace[Lookup[o,"MasterCountReason",None],None->"Caller supplied a same-loop master-count estimate"],
   "Policy"->mode,"CanStartDE"->True,"Seconds"->AbsoluteTime[]-started,"LowerLoopSourcesRetained"->True,
   "NextAction"->"If the same-loop input-plus-derivative rank exceeds the user estimate, repair the relation pool before differentiating a new basis"|>]];
 allowed=If[strategy==="TopAnnihilator",Options[TopDerivativeBound],Options[MasterIntegralCount]];
 If[!ListQ[opts]||!MatchQ[opts,{(_Rule|_RuleDelayed)...}]||Complement[First /@ opts,First /@ allowed]=!={},
  Return[fail["MasterCountOptions","MasterCountOptions must contain options supported by the chosen strategy."]]];
 If[strategy==="TopAnnihilator",
  results=TopDerivativeBound[s["Family"],#,Sequence@@Normal[Join[Association[allowed],
    <|"Workers"->o["Workers"],"KernelExecutable"->o["KernelExecutable"]|>,Association[opts],
    <|"CountScope"->"HighestLoopModuloBoundary","ProgressFunction"->o["ProgressFunction"]|>]]]& /@ s["OriginalInputs"];
  certified=AllTrue[results,AssociationQ[#]&&TrueQ[Lookup[#,"IsMasterIntegralUpperBound",False]]&];
  bound=If[certified,Total[Lookup[results,"CertifiedUpperBound"]],Missing["NotCertified"]];
  Return[<|"Status"->If[certified,"CertifiedTopUpperBound","TopBoundNotEstablished"],"Result"->results,
   "Scope"->"HighestLoopModuloBoundary","LoopCount"->s["Family"]["LoopCount"],
   "LoopUpperBounds"->Association@Table[k->If[k===s["Family"]["LoopCount"],bound,Missing["SeparateCountRequired"]],{k,s["Family"]["LoopCount"],1,-1}],
   "Seconds"->AbsoluteTime[]-started,"CanStartDE"->(certified||mode==="Advisory"),"Policy"->mode,
   "CertifiedUpperBound"->bound,"IsMasterIntegralUpperBound"->certified,
   "LowerLoopSourcesRetained"->True,"MultipleInputCombination"->"Sum of per-input cyclic bounds; overlaps can lower the actual dimension"|>]];
 result=MasterIntegralCount[s["Family"],s["OriginalInputs"],Sequence@@Normal[Join[
   Association[Options[MasterIntegralCount]],Association[opts],<|"TotalTimeLimit"->Lookup[o,"MasterCountTimeLimit",60],"ProgressFunction"->o["ProgressFunction"]|>]]];
 <|"Status"->If[FailureQ[result],"CountFailed",result["Status"]],"Result"->result,
  "Seconds"->AbsoluteTime[]-started,"CanStartDE"->(mode==="Advisory"),"Policy"->mode,
  "LoopCount"->s["Family"]["LoopCount"],"LoopUpperBounds"->Association@Table[k->Missing["NotCertified"],{k,s["Family"]["LoopCount"],1,-1}],
  "CertifiedUpperBound"->Missing["NotCertified"],"IsMasterIntegralUpperBound"->False,
  "NextAction"->"Complete the representation, infinity and specialization checks before using the count as a termination bound"|>];

masterCountRankAudit[s_,input_,de_]:=Module[{pre=Lookup[s,"MasterCountPreflight",<||>],vars,ci,cd,ri,rj,u,user,certified,highInput,highDE},
 certified=TrueQ[Lookup[pre,"IsMasterIntegralUpperBound",False]];
 user=Lookup[pre,"ThresholdOrigin",None]==="UserEstimate" && TrueQ[Lookup[pre,"HasStoppingThreshold",False]];
 If[!certified&&!user,Return[<|"BoundAvailable"->False,"Exceeded"->False|>]];
 If[!user && !TrueQ[Lookup[s,"TopBoundBasisScopePreserved",True]],Return[<|"BoundAvailable"->True,"ApplicableToCurrentBasis"->False,"Exceeded"->False,
  "Reason"->"The chosen ordering basis enlarged the actual top-generated span; the top bound does not bound those additional directions",
  "CertifiedTopUpperBound"->pre["CertifiedUpperBound"],"NextAction"->"Retain all directions and establish a bound for the enlarged input space"|>]];
 highInput=input/._BoundaryIntegral->0;highDE=de/._BoundaryIntegral->0;
 vars=support[{highInput,highDE}];ci=coeff[highInput,vars];cd=coeff[highDE,vars];ri=Length[rr[ci]];rj=Length[rr[Join[ci,cd]]];
 u=If[user,pre["StoppingThreshold"],pre["CertifiedUpperBound"]];
 <|"BoundAvailable"->certified,"HasStoppingThreshold"->True,"ApplicableToCurrentBasis"->True,"LoopCount"->s["Family"]["LoopCount"],"Scope"->"HighestLoopModuloBoundary",
  "ThresholdOrigin"->If[user,"UserEstimate","CertifiedTopBound"],"StoppingThreshold"->u,"UserEstimatedUpperBound"->If[user,u,Missing["NotUserEstimated"]],
  "InputRank"->ri,"InputAndDerivativeRank"->rj,"CertifiedUpperBound"->If[certified,u,Missing["UserEstimateNotCertified"]],"Exceeded"->(rj>u),
  "NextAction"->If[rj>u,"Repair relations before expanding the DE basis","Continue closure test"],"LowerLoopSourcesRetained"->True|>];
