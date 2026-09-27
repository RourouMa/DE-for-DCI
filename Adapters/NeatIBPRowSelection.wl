(* Optional numeric row selector. Load NeatIBP/SparseRREF/SparseRREF.m first.
   Implements the independent-row and augmented-identity selection strategy
   described in NeatIBP's IndepedentSet and UsedRelations, on arbitrary columns.
   This returns ORIGINAL row numbers, never sampled equations for production.
   Keep every boundary/source column. A full-system reference check is required
   before accepting a symbolic target reduction from the selected rows. *)
BeginPackage["ConformalIBPNeatSelection`"];
SelectSparseTargetRows::usage="SelectSparseTargetRows[numericSparseMatrix,targetColumnNumbers,prime] selects original equations using SpaSM and target provenance; returns a numerical heuristic, not a symbolic certificate.";
SelectCoefficientTargetRows::usage="SelectCoefficientTargetRows[numericSparseMatrix,targetColumnNumbers,prime] selects original equations using a weighted elimination DAG, without forming an augmented identity matrix. Requires Python 3.9 or newer.";
NeatTargetSolve::usage="NeatTargetSolve[originalEquations,orderedIntegralColumns,targetAtoms] selects original rows with SpaSM, CoefficientDAG, or AggregateCoefficientDAG, reconstructs only requested normal forms with FiniteFlow, and checks targets plus free images against the full system. Requires ConformalIBP and FiniteFlow.";
Begin["`Private`"];
adapterDirectory=DirectoryName[$InputFileName];
nonzero[m_]:=Most[ArrayRules[m]];
pivotPairs[m_]:=SortBy[({#[[1,1,1]],Min[#[[All,1,2]]]}& /@ GatherBy[nonzero[m],#[[1,1]]&]),Last];
Options[SelectSparseTargetRows]={"InputRowsIndependent"->False};
SelectSparseTargetRows[m_SparseArray,targets_List,prime_Integer,OptionsPattern[]]:=Module[
 {nr,nc,independent,b,aug,rref,pairs,rowForColumn,used,selected,started=AbsoluteTime[],t,indSeconds,trackSeconds,entries},
 If[Length[Dimensions[m]]=!=2||m["ImplicitValue"]=!=0,Return[Failure["SparseMatrixInput",<||>]]];
 {nr,nc}=Dimensions[m];
 (* NeatIBP's compatible SpaSM uses 32-bit products and caps p at 46337.
    Reject larger primes: the library silently changes the field otherwise. *)
 If[!PrimeQ[prime]||prime>46337||!VectorQ[m["NonzeroValues"],IntegerQ]||
    !VectorQ[targets,IntegerQ[#]&&1<=#<=nc&],Return[Failure["NumericInput",<||>]]];
 If[nr===0||m["NonzeroValues"]==={},Return[<|"Rows"->{},"Rank"->0,"PivotColumns"->{},"FreeColumns"->Range[nc],"Prime"->prime,"SymbolicallyCertified"->False|>]];
 t=AbsoluteTime[];
 independent=If[TrueQ[OptionValue["InputRowsIndependent"]],Range[nr],SparseRREF`SRFindPivots[Transpose[m],Modulus->prime]];
 If[!ListQ[independent]||!DuplicateFreeQ[independent]||!VectorQ[independent,IntegerQ[#]&&1<=#<=nr&],Return[Failure["SpaSMPivots",<|"Result"->independent|>]]];
 indSeconds=N[AbsoluteTime[]-t];
 If[independent==={},Return[<|"Rows"->{},"Rank"->0,"PivotColumns"->{},"FreeColumns"->Range[nc],"Prime"->prime,"SymbolicallyCertified"->False|>]];
 b=m[[independent,All]];t=AbsoluteTime[];
 aug=Transpose[Join[Transpose[b],IdentityMatrix[Length[independent],SparseArray]]];
 rref=SparseRREF`SRSparseRowReduce[aug,Modulus->prime];
 If[Head[rref]=!=SparseArray,Return[Failure["SpaSMRREF",<||>]]];
 pairs=pivotPairs[rref[[All,1;;nc]]];
 If[Length[pairs]=!=Length[independent],Return[Failure["SpaSMRankMismatch",<||>]]];
 rowForColumn=AssociationThread[pairs[[All,2]],pairs[[All,1]]];
 used=Lookup[rowForColumn,Intersection[targets,Keys[rowForColumn]]];
 entries=If[used==={},{},nonzero[rref[[used,nc+1;;]]]];
 selected=Union[If[entries==={},{},entries[[All,1,2]]]];
 trackSeconds=N[AbsoluteTime[]-t];
 <|"Rows"->Sort[independent[[selected]]],"IndependentRows"->independent,
   "Rank"->Length[independent],"PivotColumns"->Sort[Keys[rowForColumn]],
   "FreeColumns"->Complement[Range[nc],Keys[rowForColumn]],"Prime"->prime,
   "IndependentSelectionSeconds"->indSeconds,"IndependentRowsSupplied"->TrueQ[OptionValue["InputRowsIndependent"]],"ProvenanceSeconds"->trackSeconds,
   "Seconds"->N[AbsoluteTime[]-started],"AugmentedRREFNonzeros"->Length[rref["NonzeroValues"]],
   "SymbolicallyCertified"->False,"InputColumnsPreserved"->True|>
];
Options[SelectCoefficientTargetRows]={"PythonExecutable"->"python3","InputRowsIndependent"->False,"ShortRowsFirst"->True,"AggregateCount"->0,"AggregateSeed"->260926};
SelectCoefficientTargetRows[m_SparseArray,targets_List,prime_Integer,OptionsPattern[]]:=Module[
 {nr,nc,entries,directory,input,output,process,result,python=OptionValue["PythonExecutable"],aggregate=OptionValue["AggregateCount"],seed=OptionValue["AggregateSeed"]},
 If[Length[Dimensions[m]]=!=2||m["ImplicitValue"]=!=0,Return[Failure["SparseMatrixInput",<||>]]];
 {nr,nc}=Dimensions[m];
 If[!PrimeQ[prime]||prime>2147483647||!VectorQ[m["NonzeroValues"],IntegerQ]||
  !VectorQ[targets,IntegerQ[#]&&1<=#<=nc&]||!StringQ[python]||!IntegerQ[aggregate]||!Between[aggregate,{0,32}]||!IntegerQ[seed],Return[Failure["NumericInput",<||>]]];
 entries=Append[First[#],Last[#]]& /@ nonzero[m];
 directory=CreateDirectory[];input=FileNameJoin[{directory,"input.json"}];output=FileNameJoin[{directory,"selection.json"}];
 Export[input,<|"Rows"->nr,"Columns"->nc,"Targets"->targets,"ShortRowsFirst"->TrueQ[OptionValue["ShortRowsFirst"]],
   "Samples"->{<|"Prime"->prime,"Entries"->entries|>}|>,"RawJSON"];
 process=Quiet[Check[RunProcess[{python,FileNameJoin[{adapterDirectory,"coefficient_provenance.py"}],input,output,"--omit-certificates","--aggregates",ToString[aggregate],"--seed",ToString[seed]}],$Failed]];
 result=If[AssociationQ[process]&&process["ExitCode"]===0&&FileExistsQ[output],
   Quiet[Check[Import[output,"RawJSON"],$Failed]],$Failed];
 Quiet[DeleteDirectory[directory,DeleteContents->True]];
 If[!AssociationQ[result],Return[Failure["CoefficientSelectorProcess",<|"Process"->process|>]]];
 If[!If[aggregate===0,TrueQ[result["AllOriginalRowCertificatesChecked"]],TrueQ[result["AggregateIdentitiesChecked"]]]||!DuplicateFreeQ[result["Rows"]]||
  !VectorQ[result["Rows"],IntegerQ[#]&&1<=#<=nr&],Return[Failure["CoefficientSelectorOutput",<||>]]];
 If[TrueQ[OptionValue["InputRowsIndependent"]]&&result["Rank"]=!=nr,Return[Failure["CoefficientSelectorRankMismatch",<||>]]];
 result
];
Options[NeatTargetSolve]={"SelectionPrime"->42013,"Parameters"->Automatic,"NumericalPoint"->Automatic,"ShortRowsFirst"->True,"InputRowsIndependent"->False,"MaxPrimes"->80,"SelectionMethod"->"SpaSM","PythonExecutable"->"python3","AggregateCount"->2,"AggregateSeed"->260926};
NeatTargetSolve[rows_List,columns_List,targets_List,OptionsPattern[]]:=Module[
 {maps,values,parameters,point,prime=OptionValue["SelectionPrime"],pos,triples,numeric,m,order,selection,ids,
  rawRules,images,keep,rules,reference,referenceParameters,referencePoint,free,witness,started=AbsoluteTime[],selectionSeconds,solveSeconds,t},
 If[!MemberQ[$Packages,"ConformalIBP`"]||!MemberQ[$Packages,"FiniteFlow`"],Return[Failure["DependenciesNotLoaded",<||>]]];
 If[!DuplicateFreeQ[columns]||!AllTrue[columns,MatchQ[#,_ConformalIBP`G|_ConformalIBP`BoundaryIntegral]&]||
  Complement[targets,columns]=!={},Return[Failure["IntegralColumns",<||>]]];
 If[rows==={}||targets==={},Return[<|"Rules"->Thread[targets->targets],"ReducedTargets"->targets,"SelectedRows"->{},"FullPoolTargetAgreement"->True,"VerificationScope"->"EmptyInputOrTargets"|>]];
 maps=ConformalIBP`Private`linearMapNoExpand /@ rows;
 If[AnyTrue[maps,FailureQ]||Complement[Union[Flatten[Keys /@ maps]],columns]=!={},Return[Failure["LinearInput",<||>]]];
 values=Flatten[Values /@ maps];
 If[values==={},Return[<|"Rules"->Thread[targets->targets],"ReducedTargets"->targets,"SelectedRows"->{},"FullPoolTargetAgreement"->True,"VerificationScope"->"IdenticallyZeroInputSystem"|>]];
 parameters=OptionValue["Parameters"];
 If[parameters===Automatic,parameters=Union[Flatten[Variables /@ values]]];
 point=OptionValue["NumericalPoint"];
 If[point===Automatic,point=If[Length[parameters]===2,{11,17},Prime[Range[Length[parameters]]+4]]];
 If[!ListQ[point]||Length[point]=!=Length[parameters]||!VectorQ[point,IntegerQ],Return[Failure["NumericalPoint",<||>]]];
 pos=AssociationThread[columns,Range[Length[columns]]];
 triples=Flatten[MapIndexed[With[{i=First[#2]},KeyValueMap[{i,pos[#1],#2}&,#1]]&,maps],1];
 numeric=Together /@ (triples[[All,3]]/.Thread[parameters->point]);
 If[!VectorQ[numeric,MatchQ[#,_Integer|_Rational]&]||!IntegerQ[prime]||!PrimeQ[prime]||prime>46337||
  AnyTrue[numeric,Mod[Denominator[#],prime]===0&],Return[Failure["SelectionPointOrPrime",<||>]]];
 numeric=Mod[Numerator[#]PowerMod[Denominator[#],-1,prime],prime]& /@ numeric;
 m=SparseArray[MapThread[Rule,{triples[[All,{1,2}]],numeric}],{Length[rows],Length[columns]}];
 order=If[TrueQ[OptionValue["ShortRowsFirst"]],SortBy[Range[Length[rows]],{Length[maps[[#]]],LeafCount[rows[[#]]],ByteCount[rows[[#]]],#}&],Range[Length[rows]]];
 selection=Switch[OptionValue["SelectionMethod"],
  "SpaSM",SelectSparseTargetRows[m[[order]],pos /@ targets,prime,"InputRowsIndependent"->OptionValue["InputRowsIndependent"]],
  "CoefficientDAG",SelectCoefficientTargetRows[m[[order]],pos /@ targets,prime,
   "InputRowsIndependent"->OptionValue["InputRowsIndependent"],"PythonExecutable"->OptionValue["PythonExecutable"],
   "ShortRowsFirst"->OptionValue["ShortRowsFirst"]],
  "AggregateCoefficientDAG",SelectCoefficientTargetRows[m[[order]],pos /@ targets,prime,
   "InputRowsIndependent"->OptionValue["InputRowsIndependent"],"PythonExecutable"->OptionValue["PythonExecutable"],
   "ShortRowsFirst"->OptionValue["ShortRowsFirst"],"AggregateCount"->OptionValue["AggregateCount"],"AggregateSeed"->OptionValue["AggregateSeed"]],
  _,Failure["SelectionMethod",<|"Requested"->OptionValue["SelectionMethod"]|>]];
 If[FailureQ[selection],Return[selection]];
 ids=Sort[order[[selection["Rows"]]]];selectionSeconds=N[AbsoluteTime[]-started];t=AbsoluteTime[];
 rawRules=If[ids==={},{},FiniteFlow`FFSparseSolve[#==0& /@ rows[[ids]],columns,"NeededVars"->targets,
   "Parameters"->parameters,"SparseOutput"->True,"MaxPrimes"->OptionValue["MaxPrimes"]]];
 If[!MatchQ[rawRules,{___Rule}],Return[Failure["TargetReconstruction",<|"BackendResult"->rawRules|>]]];
 images=targets/.Dispatch[rawRules];
 keep=Union[targets,ConformalIBP`Private`support[images],ConformalIBP`Private`sources[images]];
 rules=Thread[keep->(keep/.Dispatch[rawRules])];solveSeconds=N[AbsoluteTime[]-t];
 (* FFGraphEvaluateMany requires an input coordinate even for constant
    systems. A dummy coordinate changes no equation or integral column. *)
 referenceParameters=If[parameters==={},{Unique["neatConstantParameter"]},parameters];
 referencePoint=If[parameters==={},{11},point];
 reference=If[ids==={},
  (* FF's zero-output graph cannot evaluate an all-free query. An auxiliary
     variable defined as the first target supplies one output coefficient;
     it imposes no relation on the original integral columns. *)
  witness=Unique["neatReferenceWitness"];
  ConformalIBP`Private`fullPoolNumericalAgreement[Append[rows,witness-First[keep]],Prepend[columns,witness],
    Append[keep,witness],Append[rules,witness->First[keep]],referenceParameters,{referencePoint}],
  ConformalIBP`Private`fullPoolNumericalAgreement[rows,columns,keep,rules,referenceParameters,{referencePoint}]];
 If[FailureQ[reference],Return[reference]];
 If[!TrueQ[reference["Passed"]],Return[Failure["FullPoolTargetMismatch",<|"Reference"->reference|>]]];
 free=Join[ConformalIBP`Private`support[Last /@ rules],ConformalIBP`Private`sources[Last /@ rules]];
 If[!ConformalIBP`Private`sampledRuleAgreement[free,rules,{},parameters,{point}],Return[Failure["NonIdempotentReduction",<||>]]];
 <|"Rules"->rules,"ReducedTargets"->(targets/.Dispatch[rules]),"SelectedRows"->ids,
  "Selection"->KeyDrop[selection,{"Rows","IndependentRows"}],"OriginalPoolHash"->Hash[rows,"SHA256"],
  "SelectedEquationsHash"->Hash[rows[[ids]],"SHA256"],"CheckedColumns"->keep,"FullPoolTargetAgreement"->True,
  "VerificationScope"->"FullPoolTargetNormalForms","NumericalReference"->reference,"AuxiliaryReferenceWitnessUsed"->(ids==={}),"Idempotent"->True,
  "SymbolicFullPoolResidualsChecked"->False,"SelectionSeconds"->selectionSeconds,"TargetSolveSeconds"->solveSeconds|>
];
End[];EndPackage[];
