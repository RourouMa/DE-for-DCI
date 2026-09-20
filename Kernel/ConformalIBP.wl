BeginPackage["ConformalIBP`"];
SP::usage="SP[a,b] is a symmetric embedding-space scalar product.";
G::usage="G[n1,...] denotes an integral in the active family, including unit delta indices at the end.";
BoundaryIntegral::usage="BoundaryIntegral[L,indices] is a retained lower-loop contact source in standard scalar-product order.";
CreateFamily::usage="CreateFamily[association] validates an embedding-space family, kinematics and denominator domains.";
LadderFamily::usage="LadderFamily[L,kinematics,variables] constructs the four-external-point ladder convention at any positive loop order.";
FamilyPropagators::usage="FamilyPropagators[family] returns ordered propagators including delta cuts.";
GenerateOperators::usage="GenerateOperators[family] gives verified delta-tangent rotation syzygies with loop degrees.";
GenerateSeeds::usage="GenerateSeeds[family,targets,operators] pairs component-local axial seeds with operator degrees.";
IBPRelation::usage="IBPRelation[family,operator,seed] evaluates the ordinary action and endpoint-local collision contacts.";
GenerateSystem::usage="GenerateSystem[family,targets] generates IBP and full ordinary/factorized symmetry relations.";
CanonicalIntegral::usage="CanonicalIntegral[family,G[...]] canonicalizes exact external and loop symmetries inside declared domains.";
DifferentiateIntegrals::usage="DifferentiateIntegrals[family,expressions] differentiates complete expressions before collecting targets.";
FiniteIntegralQ::usage="FiniteIntegralQ[family,expression] applies a conservative collision-cancellation test, not an arbitrary zero-sum rule.";
BuildFiniteBasis::usage="BuildFiniteBasis[family,rows] constructs a minimal constant-coefficient divergent block cover and verifies it.";
ReduceIntegrals::usage="ReduceIntegrals[family,targets,equations] performs verified Gaussian reduction, with original-domain and then factorized free representatives preferred.";
ReduceTargetIntegrals::usage="ReduceTargetIntegrals[family,targets,equations] verifies a target reduction using a dependency-selected subset of original equations and returns its certificate.";
RunReduction::usage="RunReduction[family,targets,options] generates and iterates a target reduction campaign.";
RunDE::usage="RunDE[family,inputs,options] restarts from the original inputs after every system extension and tests actual derivative closure.";
ResumeRun::usage="ResumeRun[directory] resumes a versioned, hash-checked trusted local checkpoint.";
InitializeFiniteFlow::usage="InitializeFiniteFlow[installDirectory,mathlinkDirectory] loads an optional FiniteFlow installation without hard-coded paths.";
RecommendedWorkerCount::usage="RecommendedWorkerCount[] recommends four fifths of logical processors, rounded to the nearest integer and at least one; RecommendedWorkerCount[n] uses n processors.";
$ConformalIBPVersion::usage="Package version used in checkpoint compatibility checks.";
Begin["`Private`"];
$ConformalIBPVersion="0.2.4";
RecommendedWorkerCount[n_Integer?Positive]:=Max[1,Round[4 n/5]];
RecommendedWorkerCount[]:=Module[{n=$ProcessorCount,osCount},
 If[$OperatingSystem==="Unix" && FileExistsQ["/proc/cpuinfo"],
  osCount=Length[StringCases[ReadString["/proc/cpuinfo"],RegularExpression["(?m)^processor\\s*:"]]];If[osCount>0,n=osCount]];
 If[$OperatingSystem==="Windows" && StringQ[Environment["NUMBER_OF_PROCESSORS"]] && StringMatchQ[Environment["NUMBER_OF_PROCESSORS"],DigitCharacter..],n=FromDigits[Environment["NUMBER_OF_PROCESSORS"]]];
 RecommendedWorkerCount[n]];
SetAttributes[SP,Orderless];
$packageFile=$InputFileName;
$implementationHash=Hash[Function[name,Module[{stream,data},
 stream=OpenRead[FileNameJoin[{DirectoryName[$packageFile],name}]];
 data=ReadString[stream];Close[stream];data]] /@
 {"ConformalIBP.wl","Reduction.wl","Iteration.wl","TargetReduction.wl","SeedPlanning.wl","../scripts/select-equation-rows.py","../scripts/verify-residual-worker.wls","../scripts/ibp-worker.wls","../scripts/seed-plan-worker.wls"},"SHA256"];
fail[tag_,message_,data_:<||>]:=Failure[tag,Join[<|"MessageTemplate"->message|>,data]];
zero[e_]:=TrueQ[Together[e]===0];
support[e_]:=Union[Cases[{e},_G,Infinity]];
sources[e_]:=Union[Cases[{e},_BoundaryIntegral,Infinity]];
canonicalLinear[e_]:=Module[{atoms=Join[support[e],sources[e]],terms},
 If[atoms==={},Return[If[zero[e],0,fail["NonlinearIntegralExpression","Expected an exact linear integral expression."]]]];
 terms=Quiet[Check[CoefficientRules[Expand[e],atoms],$Failed]];
 If[!ListQ[terms] || !And@@(Total[First[#]]===1 && FreeQ[Last[#],_G|_BoundaryIntegral]& /@ terms),
  Return[fail["NonlinearIntegralExpression","Expected an exact linear integral expression."]]];
 Total[(Together[Last[#]] atoms[[First[FirstPosition[First[#],1]]]])& /@ terms]];
coeff[rows_,vars_]:=Table[With[{expanded=Expand[r]},Together[Coefficient[expanded,#]]& /@ vars],{r,rows}];
rr[m_]:=If[m==={} || First[m]==={},{},Select[RowReduce[m],!And@@(zero /@ #)&]];
pivots[m_]:=First[FirstPosition[#,a_/;!zero[a],Missing[],{1},Heads->False]]& /@ m;
edges[l_]:=Join[Partition[Range[l],2,1],Complement[Subsets[Range[l],{2}],Partition[Range[l],2,1]]];
standardProps[xs_,ys_]:=Join[Flatten[Table[SP[x,y],{y,ys},{x,xs}]],SP@@ys[[#]]& /@ edges[Length[ys]]];
familyHash[f_]:=Hash[KeyDrop[f,{"Hash"}],"SHA256"];
permutationClosure[perms_,n_]:=FixedPoint[Function[group,
 Union[group,Flatten[Table[a[[b]],{a,group},{b,group}],1]]],Union[Append[perms,Range[n]]]];

CreateFamily[spec_Association]:=Module[{f,xs,ys,p,expected,top,kin,vars,gram,perms,diff,supports,ll,templates},
 f=Join[<|"Name"->"ConformalFamily","Variables"->{},"Kinematics"->{},
 "Propagators"->Automatic,"ExternalDerivatives"->Automatic,
 "ExternalPermutations"->Automatic,"SuperSectors"->{},"Completion"->"FamilyOnly",
 "IntegralOrdering"->"LadderFirst","MaxLoopPower"->2,"Dimension"->4,"FiniteValidator"->Automatic|>,spec];
 If[f["Dimension"]=!=4,Return[fail["Dimension","The built-in conformal weights and contact normalization currently require dimension four."]]];
 If[!MemberQ[{"LadderFirst","Legacy"},f["IntegralOrdering"]],Return[fail["IntegralOrdering","Use LadderFirst or Legacy."]]];
 xs=Lookup[f,"External",{}];ys=Lookup[f,"Loops",{}];vars=f["Variables"];kin=f["Kinematics"];
 If[xs==={} || ys==={} || !DuplicateFreeQ[Join[xs,ys]] || !VectorQ[Join[xs,ys,vars],MatchQ[#,_Symbol]&],
  Return[fail["InvalidVectors","External, Loops and Variables must be lists of distinct symbolic vectors/parameters."]]];
 expected=standardProps[xs,ys];p=Replace[f["Propagators"],Automatic->expected];
 If[!ListQ[p] || Sort[p]=!=Sort[expected],Return[fail["IncompleteFamily","Supply each external-loop and distinct loop-loop scalar product exactly once; ISP slots are retained."]]];
 top=Lookup[f,"TopSector",Missing[]];
 If[ListQ[top] && Length[top]===Length[p]+Length[ys],
  If[Take[top,-Length[ys]]=!=ConstantArray[1,Length[ys]],Return[fail["DeltaIndices","Delta indices must be one."]]];
  top=Take[top,Length[p]]];
 If[!ListQ[top] || Length[top]=!=Length[p] || !VectorQ[top,MemberQ[{0,1},#]&],
  Return[fail["TopSector","TopSector must be a binary denominator mask in the supplied propagator order."]]];
 gram=Table[SP[a,b],{a,xs},{b,xs}]/.kin;
 If[!FreeQ[gram,_SP] || !And@@Flatten[Map[zero,gram-Transpose[gram],{2}]],
  Return[fail["Kinematics","Kinematics must specify the entire symmetric external Gram matrix."]]];
 diff=f["ExternalDerivatives"];
 If[diff===Automatic,
  If[vars=!={} && zero[Det[gram]],Return[fail["SingularExternalGram","Supply ExternalDerivatives explicitly for a singular external Gram matrix."]]];
  diff=Association@Table[z->Map[Together,D[gram,z].Inverse[gram]/2,{2}],{z,vars}]];
 If[!AssociationQ[diff] || !ContainsAll[Keys[diff],vars] ||
  !And@@Table[Dimensions[diff[z]]==={Length[xs],Length[xs]} &&
   And@@Flatten[Map[zero,diff[z].gram+gram.Transpose[diff[z]]-D[gram,z],{2}]],{z,vars}],
  Return[fail["ExternalDerivatives","External deformation vectors do not reproduce the supplied Gram derivatives."]]];
 perms=Replace[f["ExternalPermutations"],Automatic:>Select[Permutations[Range[Length[xs]]],
   And@@Flatten[Map[zero,gram[[#,#]]-gram,{2}]]&]];
 If[!ListQ[perms] || perms==={} || !And@@(Sort[#]===Range[Length[xs]] &&
   And@@Flatten[Map[zero,gram[[#,#]]-gram,{2}]]& /@ perms),Return[fail["InvalidSymmetry","Every external permutation must preserve the external kinematics."]]];
 perms=permutationClosure[perms,Length[xs]];
 supports=Table[Flatten[Position[ys,a_/;MemberQ[List@@q,a],{1},Heads->False]],{q,p}];
 ll=Flatten[Position[Length /@ supports,2]];
 templates=Join[{Flatten[Position[top,1]]},f["SuperSectors"]];
 If[!And@@(ListQ[#] && VectorQ[#,IntegerQ] && Complement[#,Range[Length[p]]]==={}& /@ templates),
  Return[fail["SuperSectors","SuperSectors must contain explicit denominator-ID lists, not their implicit union."]]];
 If[!MemberQ[{"FamilyOnly","LadderBlocks"},f["Completion"]] || (f["Completion"]==="LadderBlocks" && Length[xs]=!=4),
  Return[fail["Completion","LadderBlocks completion requires four external vectors."]]];
 f=Join[f,<|"Propagators"->p,"DeltaPropagators"->(SP[#,#]& /@ ys),"TopSector"->top,
  "Gram"->gram,"ExternalDerivatives"->diff,"ExternalPermutations"->perms,
  "Supports"->supports,"LoopLoopIDs"->ll,"Templates"->templates,"LoopCount"->Length[ys]|>];
 Append[f,"Hash"->familyHash[f]]];

LadderFamily[l_Integer?Positive,kin_List,vars_List,OptionsPattern[{}]]:=Module[{xs,ys,top},
 xs=Array[Symbol["Global`X"<>ToString[#]]&,4];ys=Array[Symbol["Global`Y"<>ToString[#]]&,l];
 top=Join[Flatten[Table[{Boole[i==1],1,Boole[i==l],1},{i,l}]],ConstantArray[1,Max[0,l-1]],
  ConstantArray[0,Binomial[l,2]-Max[0,l-1]]];
 CreateFamily[<|"Name"->("Ladder"<>ToString[l]),"External"->xs,"Loops"->ys,
  "Kinematics"->kin,"Variables"->vars,"TopSector"->top,"Completion"->"LadderBlocks"|>]];
FamilyPropagators[f_Association]:=Join[f["Propagators"],f["DeltaPropagators"]];
validIntegral[f_,g_G]:=With[{a=List@@g},Length[a]===Length[FamilyPropagators[f]] && VectorQ[a,IntegerQ] &&
 Take[a,-f["LoopCount"]]===ConstantArray[1,f["LoopCount"]]];
weights[f_,a_List]:=Table[Total[Pick[Take[a,Length[f["Propagators"]]],MemberQ[#,i]& /@ f["Supports"]]],{i,f["LoopCount"]}];
parts[f_,g_G]:=Sort[Sort /@ ConnectedComponents[Graph[Range[f["LoopCount"]],
 UndirectedEdge@@@Pick[f["Supports"][[f["LoopLoopIDs"]]],(#!=0& /@ (List@@g)[[f["LoopLoopIDs"]]])]]]];
templates[f_,g_G]:=Module[{ps=parts[f,g],extra},
 If[f["Completion"]=!="LadderBlocks" || Length[ps]===1,Return[f["Templates"]]];
 extra=Union[Flatten[Table[Join[
  Flatten[Table[First[FirstPosition[f["Propagators"],SP[f["External"][[a]],f["Loops"][[i]]]]],{i,block},{a,{2,4}}]],
  {First[FirstPosition[f["Propagators"],SP[First[f["External"]],f["Loops"][[First[block]]]]]],
   First[FirstPosition[f["Propagators"],SP[f["External"][[3]],f["Loops"][[Last[block]]]]]]},
  (First[FirstPosition[f["Propagators"],SP@@f["Loops"][[#]]]]& /@ Partition[block,2,1])],{block,ps}]]];
 extra=Union[Complement[extra,f["LoopLoopIDs"]],Intersection[extra,f["LoopLoopIDs"],Union@@f["Templates"]]];
 Join[f["Templates"],{extra}]];
(* Negative loop-loop ISP numerators are allowed; the pole cap concerns positive powers. *)
domainQ[f_,g_G]/;validIntegral[f,g]:=With[{a=List@@g},
 And@@(#<=f["MaxLoopPower"]& /@ a[[f["LoopLoopIDs"]]]) &&
 AnyTrue[templates[f,g],Complement[Flatten[Position[Take[a,Length[f["Propagators"]]],_?Positive]],#]==={}&]];

GenerateOperators[f_Association]:=Flatten[Table[With[{rest=DeleteCases[Join[f["External"],f["Loops"]],f["Loops"][[i]]]},
 Table[<|"Loop"->i,"A"->ab[[1]],"B"->ab[[2]],
 "Degree"->(-Table[Count[ab,f["Loops"][[j]]],{j,f["LoopCount"]}])|>,{ab,Subsets[rest,{2}]}]],{i,f["LoopCount"]}],1];
relabelIDs[h_,f_,rule_]:=relabelIDs[h,f,rule]=With[{p=FamilyPropagators[f]},
 First[FirstPosition[p,#]]& /@ (p/.rule)];
relabel[f_,g_,rule_]:=Module[{a=List@@g,ids=relabelIDs[f["Hash"],f,rule]},
 G@@ReplacePart[ConstantArray[0,Length[a]],Thread[ids->a]]];
(* Portable, family-scoped mappings complement the in-kernel orbit memo.
   Workers and checkpoints carry only mappings actually requested, not full orbits. *)
symmetryKnown[h_]:=symmetryKnown[h]=<||>;
CanonicalIntegral[f_Association,g_G]:=Module[{h=f["Hash"],r},
 If[KeyExistsQ[symmetryKnown[h],g],Return[symmetryKnown[h][g]]];
 r=canonMemo[h,f,g];
 If[MatchQ[r,_G],AssociateTo[symmetryKnown[h],{g->r,r->r}]];r];
exportSymmetryCache[f_,exclude_:{}]:=Module[{m=KeyDrop[symmetryKnown[f["Hash"]],exclude],a},
 a=<|"FamilyHash"->f["Hash"],"ImplementationHash"->$implementationHash,"Mappings"->m|>;
 Append[a,"Hash"->Hash[a,"SHA256"]]];
importSymmetryCache[f_,a_Association]:=Module[{m,known=symmetryKnown[f["Hash"]],overlap,merged},
 If[Lookup[a,"FamilyHash",None]=!=f["Hash"] || Lookup[a,"ImplementationHash",None]=!=$implementationHash ||
  Lookup[a,"Hash",None]=!=Hash[KeyDrop[a,"Hash"],"SHA256"],
  Return[fail["SymmetryCacheMismatch","Symmetry cache family, implementation or content changed."]]];
 m=Lookup[a,"Mappings",None];
 If[!AssociationQ[m] || !And@@(MatchQ[#,_G] && validIntegral[f,#]& /@ Join[Keys[m],Values[m]]),
  Return[fail["SymmetryCacheShape","Invalid symmetry cache mappings."]]];
 overlap=Intersection[Keys[known],Keys[m]];merged=Join[known,m];
 If[!And@@(known[#]===m[#]& /@ overlap) ||
  !And@@(Lookup[merged,#,None]===#& /@ DeleteDuplicates[Values[m]]),
  Return[fail["SymmetryCacheConflict","Conflicting or non-idempotent symmetry mappings."]]];
 symmetryKnown[f["Hash"]]=merged;True];
(* Reuse exact index permutations and allowed-domain masks by component partition. *)
orbitIndexMaps[h_,f_,ps_]:=orbitIndexMaps[h,f,ps]=Module[{base=Range[Length[FamilyPropagators[f]]],maps,ids,extIDs,permIDs},
 extIDs=Table[First[FirstPosition[f["Propagators"],SP[f["External"][[a]],f["Loops"][[i]]]]],{i,f["LoopCount"]},{a,Length[f["External"]]}];
 permIDs=Ordering[relabelIDs[h,f,Thread[f["Loops"]->f["Loops"][[#]]]]]& /@ Permutations[Range[f["LoopCount"]]];
 maps=Table[ids=base;
 Do[Do[Do[ids[[extIDs[[i,choice[[k,a]]]]]]=extIDs[[i,a]],{a,Length[f["External"]]}],{i,ps[[k]]}],{k,Length[ps]}];
 (ids[[#]]& /@ permIDs),{choice,Tuples[f["ExternalPermutations"],Length[ps]]}];
 DeleteDuplicates[Flatten[maps,1]]];
orbitDomainRecords[h_,f_,ps_]:=orbitDomainRecords[h,f,ps]=Module[{ids,example,gs,ts},
 ids=orbitIndexMaps[h,f,ps];
 example=G@@Join[ConstantArray[0,Length[f["Propagators"]]],ConstantArray[1,f["LoopCount"]]];
 Do[Do[example=G@@ReplacePart[List@@example,First[FirstPosition[f["Propagators"],SP@@f["Loops"][[pair]]]]->1],{pair,Partition[block,2,1]}],{block,ps}];
 Table[gs=G@@(List@@example)[[id]];ts=templates[f,gs];
 {id, (Total[2^(id[[#]]-1)]& /@ ts)}, {id,ids}]];
canonMemo[h_,f_,g_]:=canonMemo[h,f,g]=Module[{a=List@@g,records,positive,ids,variants,representative},
 If[!validIntegral[f,g],Return[fail["IntegralShape","Invalid integral index vector."]]];
 If[AnyTrue[a[[f["LoopLoopIDs"]]],#>f["MaxLoopPower"]&],Return[fail["OutsideFamily","No symmetry image lies in the declared family/supersector domains."]]];
 records=orbitDomainRecords[h,f,parts[f,g]];
 positive=Total[2^(Flatten[Position[Take[a,Length[f["Propagators"]]],_?Positive]]-1)];
 ids=First /@ Select[records,Function[rec,AnyTrue[rec[[2]],BitAnd[positive,#]===positive&]]];
 variants=DeleteDuplicates[G@@a[[#]]& /@ ids];
 If[variants==={},Return[fail["OutsideFamily","No symmetry image lies in the declared family/supersector domains."]]];
 representative=If[Lookup[f,"IntegralOrdering","LadderFirst"]==="LadderFirst",
  First[SortBy[variants,{Boole[!originalDomainIntegralQ[f,#]]&,Identity}]],First[Sort[variants]]];
 Scan[(canonMemo[h,f,#]=representative)&,variants];representative];
canonExpr[f_,e_]:=Module[{gs=support[e],images},images=CanonicalIntegral[f,#]& /@ gs;
 If[AnyTrue[images,FailureQ],Return[First[Select[images,FailureQ]]]];
 canonicalLinear[e/.Dispatch[Thread[gs->images]]]];

originalDomainIntegralQ[f_,g_G]:=SubsetQ[Flatten[Position[f["TopSector"],1]],Flatten[Position[Take[List@@g,Length[f["Propagators"]]],_?Positive]]];
originalDomainExpressionQ[f_,e_]:=And@@(originalDomainIntegralQ[f,#]& /@ support[e]);
originalSeedImages[f_,g_G]:=originalSeedImages[f,g]=Module[{a=List@@g,variants},
 variants=DeleteDuplicates[(G@@a[[#]]& /@ orbitIndexMaps[f["Hash"],f,parts[f,g]])];
 Select[variants,originalDomainIntegralQ[f,#] && domainQ[f,#]&]];
Options[GenerateSeeds]={"SeedDomain"->"Original","SeedCenters"->"Raw","BlockExpansion"->"Cartesian"};
GenerateSeeds[f_Association,targets_List,ops_:Automatic,OptionsPattern[]]:=Module[{operators=Replace[ops,Automatic:>GenerateOperators[f]],
 centers,rawCenters,unmapped,records,candidates={},degrees,byDegree,ps,pools,ids,a,local,vs,combined,tuples,
 seedDomain=OptionValue["SeedDomain"],centerPolicy=OptionValue["SeedCenters"],blockPolicy=OptionValue["BlockExpansion"]},
 If[!MemberQ[{"Original","Extended"},seedDomain] || !MemberQ[{"Raw","Representative","AllOriginalImages"},centerPolicy] || !MemberQ[{"Cartesian","SingleBlock"},blockPolicy],
  Return[fail["SeedPolicy","Invalid SeedDomain, SeedCenters or BlockExpansion."]]];
 rawCenters=support[targets];
 If[!And@@(validIntegral[f,#]& /@ rawCenters),Return[fail["IntegralShape","Invalid seed center."]]];
 unmapped=If[centerPolicy==="Raw",{},Select[rawCenters,originalSeedImages[f,#]==={}&]];
 centers=Switch[centerPolicy,"Raw",rawCenters,"AllOriginalImages",Union[Flatten[originalSeedImages[f,#]& /@ rawCenters]],
  "Representative",Union[Flatten[Take[originalSeedImages[f,#],UpTo[1]]& /@ rawCenters]]];
 degrees=Union[Lookup[operators,"Degree",{}]];
 (* Enumerate each neighborhood once, then share degree batches across operators. *)
 If[operators=!={},
  Do[a=List@@g;ps=parts[f,g];
   Do[pools=Table[ids=Select[Range[Length[f["Propagators"]]],SubsetQ[block,f["Supports"][[#]]]&];
    local=Union[{a[[ids]],Boole[MemberQ[den,#]]& /@ ids}];
    vs=DeleteDuplicates[Flatten[Table[Join[{v},(v+#& /@ IdentityMatrix[Length[ids]]),
      (v-#& /@ IdentityMatrix[Length[ids]])],{v,local}],1]];
    {ids,vs},{block,ps}];
    tuples=If[blockPolicy==="Cartesian",Tuples[pools[[All,2]]],
      DeleteDuplicates[Flatten[Table[ReplacePart[(a[[#]]& /@ pools[[All,1]]),k->v],{k,Length[pools]},{v,pools[[k,2]]}],1]]];
    combined=Table[G@@Fold[ReplacePart[#1,Thread[#2[[1]]->#2[[2]]]]&,a,
      MapThread[List,{pools[[All,1]],tuple}]],{tuple,tuples}];
    candidates=Join[candidates,combined],{den,templates[f,g]}],{g,centers}];
  candidates=Select[Union[candidates],MemberQ[degrees,ConstantArray[4,f["LoopCount"]]-weights[f,List@@#]] && domainQ[f,#] &&
    (seedDomain==="Extended" || originalDomainIntegralQ[f,#])&]];
 byDegree=GroupBy[candidates,ToString[ConstantArray[4,f["LoopCount"]]-weights[f,List@@#],InputForm]&];
 records=Table[With[{op=operators[[k]]},
  <|"OperatorIndex"->k,"Degree"->op["Degree"],"Seeds"->Lookup[byDegree,ToString[op["Degree"],InputForm],{}]|>],{k,Length[operators]}];
 <|"Batches"->records,"Operators"->operators,"Centers"->centers,"UnmappedCenters"->unmapped,
  "SeedDomain"->seedDomain,"SeedCenters"->centerPolicy,"BlockExpansion"->blockPolicy,
  "Geometry"->("Component-local axial +/-1; "<>blockPolicy),
  "EmptyDegrees"->Union[Lookup[Select[records,#["Seeds"]==={}&],"Degree",{}]]|>];

scalarRules[f_]:=Join[f["Kinematics"],Thread[f["DeltaPropagators"]->0]];
integrand[f_,g_]:=Times@@MapThread[Power,{f["Propagators"],-Take[List@@g,Length[f["Propagators"]]]}];
dotVector[f_,op_,z_]:=With[{yi=f["Loops"][[op["Loop"]]],a=op["A"],b=op["B"]},SP[yi,a]SP[b,z]-SP[yi,b]SP[a,z]];
ordinary[f_,op_,g_]:=Module[{yi=f["Loops"][[op["Loop"]]],a=List@@g,p=f["Propagators"],der},
 der=Table[If[MemberQ[List@@q,yi],dotVector[f,op,First[DeleteCases[List@@q,yi]]],0],{q,p}];
 Together[-integrand[f,g] Total[Take[a,Length[p]] der/p]/.scalarRules[f]]];
contacts[f_,op_,g_]:=Module[{yi=f["Loops"][[op["Loop"]]],terms,result=0,a,b,c,vector,eff,hits,pair,expr},
 terms={{SP[yi,op["A"]],op["B"]},{-SP[yi,op["B"]],op["A"]}};
 Do[c=t[[1]];vector=t[[2]];eff=Take[List@@g,Length[f["Propagators"]]];
  Do[eff[[j]]-=Exponent[c,f["Propagators"][[j]]],{j,Length[eff]}];
  hits=Select[f["LoopLoopIDs"],eff[[#]]===2 && MemberQ[List@@f["Propagators"][[#]],yi]&];
  If[Length[hits]>1,Return[fail["OverlappingContact","A vector component has multiple endpoint collision boundaries."]]];
  Do[pair=List@@f["Propagators"][[j]];
   expr=Cancel[f["Propagators"][[j]]^2 integrand[f,g] c] SP[infinity,vector]/SP[infinity,yi];
   result-=2 Together[expr/.Last[pair]->First[pair]],{j,hits}],{t,terms}];
 Together[result/.scalarRules[f]]];
toIntegral[f_,rat_]:=Module[{e=Together[rat],p=f["Propagators"],dr,nr,terms},
 If[e===0,Return[0]];
 If[!FreeQ[e,infinity] || Complement[Cases[e,_SP,Infinity],p]=!={},Return[fail["OutsideScalarProducts","Uncancelled infinity or out-of-family scalar products remain."]]];
 dr=CoefficientRules[Denominator[e],p];nr=CoefficientRules[Numerator[e],p];
 If[Length[dr]=!=1,Return[fail["NonMonomialDenominator","The result is not a Laurent polynomial in family propagators."]]];
 terms=Total[(Last[#]/dr[[1,2]]) (G@@Join[dr[[1,1]]-First[#],ConstantArray[1,f["LoopCount"]]])& /@ nr];
 terms/.g_G:>dropEmpty[f,g]];
dropEmpty[f_,g_]:=Module[{a=List@@g,empty,keep,ys,props,ids},
 empty=Select[Range[f["LoopCount"]],Function[i,And@@Table[!MemberQ[f["Supports"][[j]],i] || a[[j]]===0,{j,Length[f["Propagators"]]}]]];
 If[empty==={},Return[g]];keep=Complement[Range[f["LoopCount"]],empty];ys=f["Loops"][[keep]];
 props=standardProps[f["External"],ys];ids=First[FirstPosition[f["Propagators"],#]]& /@ props;
 BoundaryIntegral[Length[keep],Join[a[[ids]],ConstantArray[1,Length[keep]]]]];
ordinaryShiftTemplate[h_,f_,op_]:=ordinaryShiftTemplate[h,f,op]=Module[{p=f["Propagators"],yi=f["Loops"][[op["Loop"]]],rules},
 Table[If[!MemberQ[List@@p[[j]],yi],{},
 rules=CoefficientRules[Expand[-dotVector[f,op,First[DeleteCases[List@@p[[j]],yi]]]/.scalarRules[f]],p];
 ({UnitVector[Length[p],j]-First[#],Last[#]}& /@ rules)],{j,Length[p]}]];
ordinaryShiftAction[f_,op_,g_G]:=Module[{a=Take[List@@g,Length[f["Propagators"]]],template=ordinaryShiftTemplate[f["Hash"],f,op]},
 Total[Flatten[Table[If[a[[j]]===0,{},(a[[j]] #[[2]] dropEmpty[f,G@@Join[a+#[[1]],ConstantArray[1,f["LoopCount"]]]]& /@ template[[j]])],{j,Length[a]}]]]];
shiftIBPRelation[f_Association,op_Association,seed_]:=Module[{gs=support[seed],cs,ct,ordinaryPart,result},
 If[gs==={} || !And@@(validIntegral[f,#] && weights[f,List@@#]+op["Degree"]===ConstantArray[4,f["LoopCount"]]& /@ gs),
  Return[fail["DegreeMismatch","Seed and operator degrees do not give conformal integrals."]]];
 If[Length[gs]>1 && op["Degree"]=!=ConstantArray[0,f["LoopCount"]],Return[fail["WholeOperatorDegree","Whole conformal combinations require degree-zero operators."]]];
 cs=First[coeff[{seed},gs]];ct=contacts[f,op,#]& /@ gs;
 If[AnyTrue[ct,FailureQ],Return[First[Select[ct,FailureQ]]]];
 ct=toIntegral[f,Together[cs.ct]];If[FailureQ[ct],Return[ct]];
 ordinaryPart=cs.(ordinaryShiftAction[f,op,#]& /@ gs);
 If[!FreeQ[ordinaryPart,_SP],Return[fail["OutsideScalarProducts","Uncancelled infinity or out-of-family scalar products remain."]]];
 result=canonExpr[f,ordinaryPart+ct];If[FailureQ[result],Return[result]];
 If[!And@@(domainQ[f,#] && weights[f,List@@#]===ConstantArray[4,f["LoopCount"]]& /@ support[result]),
  Return[fail["IBPDomain","IBP output violates a declared ISP domain, pole cap or conformal degree."]]];
 result];

IBPRelation[f_Association,op_Association,seed_]:=shiftIBPRelation[f,op,seed];

DifferentiateIntegrals[f_Association,expressions_List]:=Module[{rows,gs,cs,p=f["Propagators"],rat,dp,out},
 If[sources[expressions]=!={},Return[fail["BoundaryInput","Differentiate lower-loop sources in their own family; they cannot be treated as constants."]]];
 If[!And@@(validIntegral[f,#]& /@ support[expressions]),Return[fail["IntegralShape","Malformed differentiation input."]]];
 rows=Association@Table[z->Table[gs=support[e];cs=First[coeff[{e},gs]];
  dp=Table[Total[Table[If[MemberQ[List@@q,f["External"][[i]]],
    Sum[f["ExternalDerivatives"][z][[i,j]] SP[f["External"][[j]],First[DeleteCases[List@@q,f["External"][[i]]]]],{j,Length[f["External"]]}],0],{i,Length[f["External"]]}]],{q,p}];
  out=Table[rat=Together[-integrand[f,g] Total[Take[List@@g,Length[p]] dp/p]/.scalarRules[f]];toIntegral[f,rat],{g,gs}];
  If[AnyTrue[out,FailureQ],Return[First[Select[out,FailureQ]]]];
  canonicalLinear[D[cs,z].gs+cs.out],{e,expressions}],{z,f["Variables"]}];
 If[FailureQ[rows],Return[rows]];
 <|"Rows"->rows,"Targets"->support[Values[rows]],"WholeCombinationsSimplifiedFirst"->True|>];

Get[FileNameJoin[{DirectoryName[$InputFileName],"SeedPlanning.wl"}]];
Get[FileNameJoin[{DirectoryName[$InputFileName],"Reduction.wl"}]];
Get[FileNameJoin[{DirectoryName[$InputFileName],"TargetReduction.wl"}]];
Get[FileNameJoin[{DirectoryName[$InputFileName],"Iteration.wl"}]];
End[];EndPackage[];
