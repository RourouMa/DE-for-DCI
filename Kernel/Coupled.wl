(* Joint constant-coefficient kernels of complete seed/operator actions.
   Never filter a primitive action before forming the joint constraints. *)
coupledAction[f_,op_,g_]:=Module[{ct,p=f["Propagators"],e,dr,nr,extra},
 ct=contacts[f,op,g];If[FailureQ[ct],Return[ct]];e=Together[ct];
 extra=Complement[Cases[e,_SP,Infinity],p];
 If[!AllTrue[extra,!FreeQ[#,infinity]&],Return[fail["CoupledScalarProducts","Unsupported contracted scalar product."]]];
 ct=If[e===0,0,
  dr=CoefficientRules[Denominator[e],p];nr=CoefficientRules[Numerator[e],p];
  If[Length[dr]=!=1,Return[fail["CoupledDenominator","Contact action is not Laurent in propagators."]]];
  Total[(Last[#]/dr[[1,2]]) dropEmpty[f,G@@Join[dr[[1,1]]-First[#],ConstantArray[1,f["LoopCount"]]]]& /@ nr]];
 canonicalLinear[ordinaryShiftAction[f,op,g]+ct]];
(* Disjoint double collisions have separate endpoints. Each vector component
   therefore still has at most one contact boundary. Exact literal residues are
   required for EVERY pair; their iterated residues then vanish as well. *)
coupledDisjointPolesQ[f_,g_]:=With[{bad=badClusters[f,g]},
 AllTrue[bad,Length[#]===2&] && DuplicateFreeQ[Flatten[bad]] &&
 AllTrue[bad,Function[pair,(List@@g)[[First[FirstPosition[f["Supports"],pair]]]]===2]]];
coupledSeedQ[f_,g_]:=MatchQ[g,_G] && validIntegral[f,g] && domainQ[f,g] &&
 MemberQ[Lookup[GenerateOperators[f],"Degree"],ConstantArray[4,f["LoopCount"]]-weights[f,List@@g]] &&
 (Count[(List@@g)[[f["LoopLoopIDs"]]],2]<=1 || coupledDisjointPolesQ[f,g]);
coupledOutputQ[f_,g_]:=validIntegral[f,g] && domainQ[f,g] &&
 weights[f,List@@g]===ConstantArray[4,f["LoopCount"]] && coupledDisjointPolesQ[f,g];
coupledLiteralResidue[f_,e_,edge_]:=Module[{pair=List@@f["Propagators"][[edge]],gs=support[e],a},
 Together[Total[Table[a=List@@g;If[a[[edge]]=!=2,0,
 Coefficient[Expand[e],g] Cancel[f["Propagators"][[edge]]^2 integrand[f,g]]/.Last[pair]->First[pair]],{g,gs}]]/.scalarRules[f]]];
coupledConstraints[row_List,vars_List]:=Module[{r=Together /@ row,atoms},
 If[AllTrue[r,zero],Return[{}]];
 atoms=constantAtoms[{r},vars];If[atoms===$Failed || !MatrixQ[atoms,MatchQ[#,_Integer|_Rational]&],
 Return[fail["CoupledConstraints","Expected exact rational constant-kernel constraints."]]];
 DeleteCases[DeleteDuplicates[atoms],ConstantArray[0,Length[row]]]];
coupledTermsQ[f_,terms_]:=ListQ[terms] && terms=!={} && AllTrue[terms,Function[term,
 AssociationQ[term] && And@@(KeyExistsQ[term,#]& /@ {"Coefficient","Seed","Operator"}) &&
 MatchQ[term["Coefficient"],_Integer|_Rational] && coupledSeedQ[f,term["Seed"]] &&
 MemberQ[GenerateOperators[f],term["Operator"]] &&
 weights[f,List@@term["Seed"]]+term["Operator"]["Degree"]===ConstantArray[4,f["LoopCount"]]]];
CoupledIBPRelation[f_Association,terms_List]:=Module[{raw,full,contact,direct,gs,checks,relation},
 If[!coupledTermsQ[f,terms],Return[fail["CoupledTerms","Supply rational coefficients, declared-domain seeds with supported collisions and generated operators matching the output conformal weights."]]];
 raw=coupledAction[f,#["Operator"],#["Seed"]]& /@ terms;
 If[AnyTrue[raw,FailureQ],Return[First[Select[raw,FailureQ]]]];
 full=canonicalLinear[Lookup[terms,"Coefficient"].raw];
 If[FailureQ[full] || !FreeQ[full,infinity|_SP],Return[fail["CoupledInfinity","Complete action retains infinity or scalar products; no terms were discarded."]]];
 gs=support[full];If[!AllTrue[gs,coupledOutputQ[f,#]&],Return[fail["CoupledDomain","Complete output contains a forbidden domain, degree or unsupported overlapping pole."]]];
 If[!AllTrue[f["LoopLoopIDs"],zero[coupledLiteralResidue[f,full,#]]&],Return[fail["CoupledResidue","Complete output has a nonzero literal collision residue."]]];
 (* Independent rational ordinary action; contacts are summed before conversion. *)
 direct=Total[(#["Coefficient"] ordinary[f,#["Operator"],#["Seed"]])& /@ terms];
 contact=Total[(#["Coefficient"] contacts[f,#["Operator"],#["Seed"]])& /@ terms];
 direct=toIntegral[f,Together[direct+contact]];
 If[FailureQ[direct] || !zero[canonicalLinear[direct-full]],Return[fail["CoupledDirectCheck","Independent rational action disagrees with shift action."]]];
 relation=canonExpr[f,full];If[FailureQ[relation],Return[relation]];
 <|"Equation"->relation,"UncanonicalizedEquation"->full,"SeedOperatorTerms"->terms,
 "Checks"-><|"IndependentDirectAction"->True,"LiteralCollisionResiduesZero"->True,
 "NoInfinityTermsDiscarded"->True,"DomainAndDegree"->True,"BoundarySourcesRetained"->True|>,
 "FamilyHash"->f["Hash"],"ImplementationHash"->$implementationHash|>];
Options[FindCoupledIBPRelations]={"Operators"->Automatic,"ProgressFunction"->None};
FindCoupledIBPRelations[f_Association,seeds0_List,OptionsPattern[]]:=Module[
 {seeds=DeleteDuplicates[seeds0],ops,pairs,actions,blocked={},kept={},a,atoms,m,rows={},r,iv,value,vars,
 kernel,relations,resRows={},res,sp,finiteKernel,coordinates,terms,records={},rejected={},proof,n,report=OptionValue["ProgressFunction"],index,entries,byAtom,active,vals,terms0,coef0},
 If[!AllTrue[seeds,coupledSeedQ[f,#]&],Return[fail["CoupledSeeds","Coupled search needs conformal declared-domain seeds with only disjoint double collisions."]]];
 ops=Replace[OptionValue["Operators"],Automatic:>GenerateOperators[f]];
 If[!ListQ[ops] || !AllTrue[ops,MemberQ[GenerateOperators[f],#]&],Return[fail["CoupledOperators","Only generated rotation operators are supported."]]];
 pairs=Select[Tuples[{seeds,ops}],weights[f,List@@#[[1]]]+#[[2]]["Degree"]===ConstantArray[4,f["LoopCount"]]&];actions={};
 Do[a=coupledAction[f,p[[2]],p[[1]]];If[FailureQ[a],AppendTo[blocked,<|"Seed"->p[[1]],"Operator"->p[[2]],"Failure"->a|>],AppendTo[actions,a];AppendTo[kept,p]],{p,pairs}];
 n=Length[actions];If[n===0,Return[<|"Equations"->{},"Certificates"->{},"BlockedApplications"->blocked,"RejectedCandidates"->{},"PrimitiveApplications"->Length[pairs],"SupportedApplications"->0,"ContactKernelDimension"->0,"FiniteKernelDimension"->0,"SearchScope"->"Empty supported action space","NoInfinityTermsDiscarded"->True|>]];
 atoms=Join[support[actions],sources[actions]];
 index=AssociationThread[atoms,Range[Length[atoms]]];
 entries=Flatten[Table[terms0=Join[support[actions[[j]]],sources[actions[[j]]]];coef0=First[coeff[{actions[[j]]},terms0]];
 MapThread[{index[#1],j,#2}&,{terms0,coef0}],{j,n}],1];
 byAtom=GroupBy[entries,First->Rest];
 If[report=!=None,report[<|"Action"->"Sparse joint coefficient matrix assembled","Applications"->n,"Atoms"->Length[atoms],"NonzeroEntries"->Length[entries]|>]];
 Do[active=Lookup[byAtom,j,{}];If[active==={},Continue[]];r=active[[All,2]];index=active[[All,1]];iv=Union[Cases[r,s_SP/;!FreeQ[s,infinity],Infinity]];
 If[MatchQ[atoms[[j]],_G] && !coupledOutputQ[f,atoms[[j]]],Null,
  If[iv==={},Continue[]];value=Together /@ (r/.Thread[iv->Range[2,Length[iv]+1]]);
  If[!FreeQ[value,Indeterminate|ComplexInfinity|DirectedInfinity],Return[fail["CoupledEvaluation","Singular auxiliary infinity evaluation."]]];r=Together /@ (r-value)];
 vars=Union[f["Variables"],iv];a=coupledConstraints[r,vars];If[FailureQ[a],Return[a]];rows=Join[rows,(SparseArray[Thread[index->#],{n}]& /@ a)],{j,Length[atoms]}];
 rows=DeleteDuplicates[rows];kernel=If[rows==={},IdentityMatrix[n],NullSpace[SparseArray[rows]]];
 If[report=!=None,report[<|"Action"->"Coupled contact/domain kernel","Seeds"->Length[seeds],"Applications"->n,"Constraints"->Length[rows],"Dimension"->Length[kernel]|>]];
 relations=canonicalLinear[#.actions]& /@ kernel;
 If[AnyTrue[relations,FailureQ] || !FreeQ[relations,infinity|_SP],Return[fail["CoupledKernelCheck","Contact kernel failed exact cancellation."]]];
 If[kernel=!={},Do[res=coupledLiteralResidue[f,#,edge]& /@ relations;sp=Union[f["Variables"],Cases[res,_SP,Infinity]];
 a=coupledConstraints[res,sp];If[FailureQ[a],Return[a]];resRows=Join[resRows,a],{edge,f["LoopLoopIDs"]}]];
 finiteKernel=If[kernel==={},{},If[resRows==={},IdentityMatrix[Length[kernel]],NullSpace[DeleteDuplicates[resRows]]]];
 coordinates=If[finiteKernel==={},{},finiteKernel.kernel];
 Do[If[zero[canonicalLinear[v.actions]],Continue[]];terms=MapThread[<|"Coefficient"->#1,"Seed"->#2[[1]],"Operator"->#2[[2]]|>&,{v,kept}];terms=Select[terms,#["Coefficient"]=!=0&];
 proof=CoupledIBPRelation[f,terms];If[FailureQ[proof],AppendTo[rejected,<|"Terms"->terms,"Failure"->proof|>],If[!zero[proof["Equation"]],AppendTo[records,proof]]],{v,coordinates}];
 records=DeleteDuplicatesBy[records,#["Equation"]&];
 <|"Equations"->Lookup[records,"Equation",{}],"Certificates"->records,"BlockedApplications"->blocked,"RejectedCandidates"->rejected,
 "PrimitiveApplications"->Length[pairs],"SupportedApplications"->n,"ContactKernelDimension"->Length[kernel],"FiniteKernelDimension"->Length[coordinates],
 "SearchScope"->"Constant rational combinations of supplied seeds and degree-matched rotations; no completeness claim", "NoInfinityTermsDiscarded"->True|>];


(* Coupled groups run once on the coordinator, after ordinary worker merging.
   Their ledger is independent of rejected/completed primitive applications. *)
appendCoupledGroups[f_,result_,options_]:=Module[{groups=options["CoupledSeedGroups"],done=options["CompletedCoupledGroups"],
 records={},keys={},equations={},raw={},r,key,new,images,syms},
 If[groups==={},Return[result]];
 If[!ListQ[groups] || !AllTrue[groups,ListQ],Return[fail["CoupledGroups","Supply an explicit list of seed groups."]]];
 If[options["SeedDomain"]==="Original" && !AllTrue[Flatten[groups],originalDomainIntegralQ[f,#]&],Return[fail["CoupledOriginalDomain","Coupled groups contain seeds outside the requested Original domain."]]];
 Do[key=Hash[{$implementationHash,f["Hash"],Sort[DeleteDuplicates[group]],options["Operators"]},"SHA256"];
 If[MemberQ[done,key] || MemberQ[keys,key],Continue[]];
 r=FindCoupledIBPRelations[f,group,"Operators"->options["Operators"],"ProgressFunction"->options["ProgressFunction"]];
 If[FailureQ[r],Return[r]];
 AppendTo[records,r];AppendTo[keys,key];equations=Join[equations,r["Equations"]];
 raw=Union[raw,support[Lookup[r["Certificates"],"UncanonicalizedEquation",{}]]],{group,groups}];
 new=Complement[raw,options["CompletedSymmetryInputs"],result["NewSymmetryInputs"]];
 images=CanonicalIntegral[f,#]& /@ new;If[AnyTrue[images,FailureQ],Return[First[Select[images,FailureQ]]]];
 syms=canonicalLinear /@ (new-images);
 Join[result,<|"Equations"->DeleteCases[Union[result["Equations"],equations,syms],0],
 "SymmetryInputs"->Union[result["SymmetryInputs"],raw],"NewSymmetryInputs"->Union[result["NewSymmetryInputs"],new],
 "CoupledSearches"->records,"CompletedCoupledGroups"->keys,
 "AllActualSeedsInsideOriginalDomain"->(result["AllActualSeedsInsideOriginalDomain"] && AllTrue[Flatten[groups],originalDomainIntegralQ[f,#]&])|>]];
