(* Constant integral blocks; all kinematic dependence stays in DE weights.
   Accepted blocks are substituted globally before another is searched for. *)
Clear[ConstantDECoefficientBlocks];
ConstantDECoefficientBlocks[c0_,variables_,tag_,known0_:{}] := Module[
 {c=Map[Together,c0,{2}],n=Length[variables],atomsOf,normalize,score,
  atomRows,atomOrigins,envelope,piv,rank,residual,b={},history={},eliminated={},
  known,knownEvents={},weights,certificates,inside,reduceKnown,accept,
  candidates,origins,seen,add,scanPairs,scanGroups,scanAtoms,phase,chosen,
  nonzero,den,polys,powers,a,i,j,group,groups,coeff,key,t,v,q,p,scale,step=0,
  before,after,remainingRank,checks,sourceWeights,initialRows,backwardMoves={},
  changed,pairIDs,pairSupport,ratio,trial,quotientRows,pairGroups,pairRank,
  extractedRows,extractedPivots,derivedTransform,edges,existingEdges,parent,rootOf,
  forest,orderedForest,orderedPivots,degrees,leaves,remainingEdges,edge,pivot,
  reducedBlocks,finalRows,finalPivots,finalHistory={},weight,edgeOrder,shortSearch=None,dual,active},
 normalize[row_]:=Module[{r=Together /@ row,d,g,active},
  active=Select[r,#=!=0&];If[active==={},Return[r]];
  If[!And@@(MatchQ[#,_Integer|_Rational]& /@ active),Return[$Failed]];
  d=LCM@@(Denominator /@ active);r=d r;g=GCD@@Abs[r];
  r=Sign[First[Select[r,#!=0&]]] r/g;r];
 score[row_]:={Count[row,Except[0]],Total[Abs[row]],Max[Abs[row]]};
 atomsOf[m_]:=Module[{aa={},oo={},dd,pp,ee,rr},
  Do[
   dd=PolynomialLCM@@(Denominator /@ m[[ii]]);
   pp=Expand[Together[dd #]]& /@ m[[ii]];
   If[!And@@(PolynomialQ[#,{x,y}]& /@ pp),Return[$Failed]];
   ee=Union[Flatten[(First /@ CoefficientRules[#,{x,y}]& /@ pp),1]];
   Do[
    rr=Coefficient[Coefficient[#,x,e[[1]]],y,e[[2]]]& /@ pp;
    If[AnyTrue[rr,#!=0&],AppendTo[aa,rr];AppendTo[oo,
     <|"SourceRow"->ii,"Monomial"->e,"Scalar"->Together[x^e[[1]] y^e[[2]]/dd]|>]],
    {e,ee}],{ii,Length[m]}];{aa,oo}];
 If[n==0,Return[<|"Rows"->{},"Definitions"->{},"Weights"->ConstantArray[{},Length[c]],
  "ConstantRank"->0,"VariableCoefficientRank"->0,"OriginalCoefficientRows"->c,
  "CoefficientAtoms"->{},"AtomOrigins"->{},"ConstantEnvelopeRREF"->{},"EnvelopePivots"->{},
  "BlockEnvelopeCoordinates"->{},"EliminationPivots"->{},"SubstitutionHistory"->{},
  "Checks"-><|"NoXYInsideAnyBlock"->True,"PrimitiveIntegerBlockCoefficients"->True,
   "EveryBlockZeroSum"->True,"ExactGlobalInputAndDECoverage"->True,
   "NoDivergentResidualAfterAllSubstitutions"->True,"MinimumCountForConstantCoefficientCoverage"->True,
   "AllBlocksInActualConstantCoefficientEnvelope"->True,"OldPivotCannotReappearInLaterBlock"->True,
   "IndependentConstantBlocks"->True|>,"SupportHistogram"-><||>,
  "FinitenessStatus"->"No divergent block required","SimplicityStatus"->"Empty basis"|>]];
 If[!And@@(itZero[Total[#]]& /@ c),Print["Nonzero-sum source residual"];Return[$Failed]];
 {atomRows,atomOrigins}=atomsOf[c];envelope=itRR[atomRows];piv=itPiv[envelope];rank=Length[envelope];
 quotientRows=IdentityMatrix[n]-IdentityMatrix[n][[All,piv]].envelope;
 pairGroups=GatherBy[Range[n],quotientRows[[#]]&];pairRank=n-Length[pairGroups];
 inside[row_]:=And@@(itZero /@ (row-row[[piv]].envelope));
 residual=c;
 reduceKnown[row_]:=Module[{rr=row},
  Do[rr=Together /@ (rr-rr[[eliminated[[ii]]]] b[[ii]]/b[[ii,eliminated[[ii]]]]),
   {ii,Length[b]}];rr];
 accept[row_,origin_]:=Module[{r=normalize[row],pivot,weight},
  If[r===$Failed || !FreeQ[r,x|y] || !itZero[Total[r]] || !inside[r],Return[$Failed]];
  If[!And@@(itZero /@ r[[eliminated]]),Return[$Failed]];
  pivot=First[Select[Range[n],r[[#]]!=0&]];
  weight=Together /@ (residual[[All,pivot]]/r[[pivot]]);
  AppendTo[b,r];AppendTo[eliminated,pivot];
  residual=Map[Together,residual-Outer[Times,weight,r],{2}];
  AppendTo[history,<|"Block"->Length[b],"Origin"->origin,"PivotColumn"->pivot,
   "GlobalExtractionWeights"->weight,"ResidualHash"->Hash[residual,"SHA256"],
   "ResidualNonzeroColumns"->Count[Transpose[residual],col_/;AnyTrue[col,#=!=0&]]|>];True];

 (* Existing constant blocks are removed from every row first. If a known
    block contains an earlier one, only its new constant remainder is kept. *)
 known=known0;
 Do[
  v=reduceKnown[known[[i]]];
  If[!And@@(itZero /@ v),
   If[accept[v,<|"Kind"->"KnownConstantBlockRemainder","KnownPosition"->i|>]===$Failed,
    Print["Unsupported known block"];Return[$Failed]]],{i,Length[known]}];

 add[row_,origin_]:=Module[{r=normalize[row],id},
  If[r===$Failed || And@@(itZero /@ r) || !itZero[Total[r]],Return[]];
  If[!And@@(itZero /@ r[[eliminated]]) || !inside[r],Return[]];
  id=ToString[r,InputForm];If[!KeyExistsQ[seen,id],
   AssociateTo[seen,id->True];AppendTo[candidates,r];AppendTo[origins,origin]]];
 scanPairs[]:=Do[
  nonzero=Select[Range[n],residual[[i,#]]=!=0&];
  Do[If[itZero[residual[[i,ij[[1]]]]+residual[[i,ij[[2]]]]],
   add[ReplacePart[ConstantArray[0,n],{ij[[1]]->1,ij[[2]]->-1}],
    <|"Kind"->"OppositeFullResidualCoefficients","SourceRow"->i,"Columns"->ij,
      "ExtractedCoefficient"->residual[[i,ij[[1]]]]|>]],{ij,Subsets[nonzero,{2}]}],
  {i,Length[residual]}];
 scanGroups[]:=Do[
  nonzero=Select[Range[n],residual[[i,#]]=!=0&];
  groups={};
  Do[
   group=SelectFirst[Range[Length[groups]],
    MatchQ[Together[residual[[i,j]]/residual[[i,First[groups[[#]]]]]],_Integer|_Rational]&,0];
   If[group==0,AppendTo[groups,{j}],AppendTo[groups[[group]],j]],{j,nonzero}];
  Do[
   v=ReplacePart[ConstantArray[0,n],Thread[g->(Together /@
    (residual[[i,g]]/residual[[i,First[g]]]))]];
   add[v,<|"Kind"->"BalancedProportionalResidualGroup","SourceRow"->i,"Columns"->g|>],
   {g,groups}],{i,Length[residual]}];
 scanAtoms[]:=Module[{aa,oo,positive,negative},
  {aa,oo}=atomsOf[residual];
  Do[
   positive=Select[Range[n],aa[[ii,#]]>0&];negative=Select[Range[n],aa[[ii,#]]<0&];
   Do[add[ReplacePart[ConstantArray[0,n],{ij[[1]]->1,ij[[2]]->-1}],
    <|"Kind"->"OppositeResidualCoefficientFragments","AtomSource"->oo[[ii]],"Columns"->ij|>],
    {ij,Tuples[{positive,negative}]}];
   add[aa[[ii]],<|"Kind"->"BalancedResidualCoefficientAtom","AtomSource"->oo[[ii]]|>],
   {ii,Length[aa]}]];
 Print[{"Constant-coefficient lower bound",rank,"Known directions replaced",Length[b]}//InputForm];
 While[!And@@Flatten[Map[itZero,residual,{2}]],
  candidates={};origins={};seen=<||>;
  scanPairs[];phase="full opposite coefficients";
  If[candidates==={},scanGroups[];scanAtoms[];phase="balanced residual groups and fragments"];
  If[candidates==={},Print["Uncovered residual has no supported constant block"];Return[$Failed]];
  chosen=First[SortBy[Range[Length[candidates]],{score[candidates[[#]]]&,Identity}]];
  If[accept[candidates[[chosen]],origins[[chosen]]]===$Failed,Return[$Failed]];
  If[Length[b]>rank,Print["Constant span unnecessarily enlarged"];Return[$Failed]];
  Print[{"Extracted constant block",Length[b],"Terms",Count[Last[b],Except[0]],"Phase",phase}//InputForm]];

 (* A later discovered pair can remove a complete sub-block of an earlier
    definition. These invertible subtractions retain count and constant span. *)
 initialRows=b;changed=True;
 While[changed,
  changed=False;pairIDs=Select[Range[Length[b]],Count[b[[#]],Except[0]]==2&];
  Do[If[Count[b[[i]],Except[0]]>2,
   Do[If[i!=j,
    pairSupport=Select[Range[n],b[[j,#]]!=0&];
    If[And@@(b[[i,#]]!=0& /@ pairSupport),
     ratio=b[[i,First[pairSupport]]]/b[[j,First[pairSupport]]];
     If[And@@(b[[i,#]]==ratio b[[j,#]]& /@ pairSupport),
      trial=normalize[b[[i]]-ratio b[[j]]];
      If[trial=!=$Failed && AnyTrue[trial,#!=0&] &&
        Count[trial,Except[0]]<Count[b[[i]],Except[0]],
       AppendTo[backwardMoves,<|"Block"->i,"SubtractBlock"->j,"Factor"->ratio,
        "Before"->b[[i]],"After"->trial|>];b[[i]]=trial;changed=True]]]],{j,pairIDs}]],
   {i,Length[b]}]];
 Print[{"Backward pair substitutions",Length[backwardMoves],
  "Final support",Counts[Count[#,Except[0]]& /@ b],"Maximum independent pair directions",pairRank}//InputForm];

 (* Derive additional simple pairs from the span of already extracted
    finite blocks, with an exact basis-change certificate. This does not
    declare differences between arbitrary raw integrals to be finite. *)
 extractedRows=b;extractedPivots=eliminated;
 existingEdges=Select[Table[Select[Range[n],b[[ii,#]]!=0&],{ii,Length[b]}],Length[#]==2&];
 edges=DeleteDuplicates[Join[existingEdges,Flatten[Subsets[#,{2}]& /@ pairGroups,1]]];
 parent=Range[n];rootOf[ii_]:=If[parent[[ii]]==ii,ii,rootOf[parent[[ii]]]];
 forest={};
 Do[If[rootOf[First[edge]]!=rootOf[Last[edge]],AppendTo[forest,edge];
   parent[[rootOf[First[edge]]]]=rootOf[Last[edge]]],{edge,edges}];
 If[Length[forest]!=pairRank,Return[$Failed]];
 orderedForest={};orderedPivots={};remainingEdges=forest;
 While[remainingEdges=!={},
  degrees=Counts[Flatten[remainingEdges]];
  leaves=Sort[Select[Keys[degrees],degrees[#]==1&]];pivot=First[leaves];
  edge=SelectFirst[remainingEdges,MemberQ[#,pivot]&];
  AppendTo[orderedForest,edge];AppendTo[orderedPivots,pivot];
  remainingEdges=DeleteCases[remainingEdges,edge]];
 finalRows=Table[ReplacePart[ConstantArray[0,n],{First[edge]->1,Last[edge]->-1}],{edge,orderedForest}];
 finalPivots=orderedPivots;reducedBlocks=extractedRows;
 Do[reducedBlocks=reducedBlocks-Outer[Times,
   reducedBlocks[[All,finalPivots[[i]]]]/finalRows[[i,finalPivots[[i]]]],finalRows[[i]]],
   {i,Length[finalRows]}];
 While[AnyTrue[Flatten[reducedBlocks],#!=0&],
  candidates=DeleteDuplicates[normalize /@ Select[reducedBlocks,AnyTrue[#,#!=0&]&]];
  v=First[SortBy[candidates,score]];pivot=First[Select[Range[n],v[[#]]!=0&]];
  AppendTo[finalRows,v];AppendTo[finalPivots,pivot];
  reducedBlocks=reducedBlocks-Outer[Times,reducedBlocks[[All,pivot]]/v[[pivot]],v]];
 If[Max[Count[#,Except[0]]& /@ finalRows]>4,
  shortSearch=ShortConstantFiniteBasis[finalRows];If[shortSearch===$Failed,Return[$Failed]];
  finalRows=shortSearch["Rows"];finalPivots=itPiv[itRR[finalRows]];
  Print[{"Certified short-block refinement",KeyDrop[shortSearch,{"Rows","Transformation","SparsifyingMoves"}]}//InputForm]];
 derivedTransform=finalRows[[All,extractedPivots]].Inverse[extractedRows[[All,extractedPivots]]];
 If[Length[finalRows]!=rank || !And@@(MatchQ[#,_Integer|_Rational]& /@ Flatten[derivedTransform]) ||
   finalRows=!=derivedTransform.extractedRows,Print["Finite-block basis change failed"];Return[$Failed]];
 b=finalRows;eliminated=finalPivots;
 Print[{"Simple pairs derived from existing finite blocks",Count[b,row_/;Count[row,Except[0]]==2],
  "Final constant blocks",Length[b],"Support",Counts[Count[#,Except[0]]& /@ b]}//InputForm];

 (* Dual coordinates remove whole finite blocks globally even when the
    shortest raw-integral definitions are not a triangular basis. *)
 dual=Inverse[b[[All,eliminated]]];
 residual=c;weights=ConstantArray[0,{Length[c],Length[b]}];
 Do[
  active=Select[Range[Length[b]],dual[[#,i]]!=0&];
  weights[[All,i]]=Together /@ (residual[[All,eliminated[[active]]]].dual[[active,i]]);
  residual=Map[Together,residual-Outer[Times,weights[[All,i]],b[[i]]],{2}];
  AppendTo[finalHistory,<|"Block"->i,"CoordinateColumns"->eliminated,"DualVector"->dual[[All,i]],
   "Weights"->weights[[All,i]],"ResidualHash"->Hash[residual,"SHA256"]|>],{i,Length[b]}];
 certificates=b[[All,piv]];
 checks=<|"NoXYInsideAnyBlock"->FreeQ[b,x|y],
  "PrimitiveIntegerBlockCoefficients"->And@@(IntegerQ /@ Flatten[b]),
  "EveryBlockZeroSum"->And@@(itZero[Total[#]]& /@ b),
  "ExactGlobalInputAndDECoverage"->And@@Flatten[Map[itZero,c-Normal[SparseArray[weights].SparseArray[b]],{2}]],
  "NoDivergentResidualAfterAllSubstitutions"->And@@Flatten[Map[itZero,residual,{2}]],
  "MinimumCountForConstantCoefficientCoverage"->(Length[b]==rank),
  "AllBlocksInActualConstantCoefficientEnvelope"->And@@Flatten[Map[itZero,certificates.envelope-b,{2}]],
  "BiorthogonalFiniteExtractionCoordinates"->(b[[All,eliminated]].dual===IdentityMatrix[Length[b]]),
  "IndependentConstantBlocks"->(Length[itRR[b]]==rank)|>;
 AssociateTo[checks,{"EveryFinalBlockDerivedFromExtractedFiniteBlocks"->
  (b===derivedTransform.extractedRows),"MaximumNumberOfIndependentPairs"->
  (Count[b,row_/;Count[row,Except[0]]==2]==pairRank)}];
 If[!And@@Values[checks],Print[checks//InputForm];Return[$Failed]];
 <|"Rows"->b,"Definitions"->MapIndexed[ActualFinite[tag,First[#2]]->(#1.variables)&,b],
  "Weights"->weights,"ConstantRank"->rank,"VariableCoefficientRank"->Length[itRR[c]],
  "OriginalCoefficientRows"->c,"CoefficientAtoms"->atomRows,"AtomOrigins"->atomOrigins,
  "ConstantEnvelopeRREF"->envelope,"EnvelopePivots"->piv,"BlockEnvelopeCoordinates"->certificates,
  "EliminationPivots"->eliminated,"SubstitutionHistory"->history,"InitialExtractedRows"->initialRows,
  "BackwardSimplifications"->backwardMoves,"ExtractedFiniteRows"->extractedRows,
  "FinalFromExtractedFiniteBlocks"->derivedTransform,"FinalSubstitutionHistory"->finalHistory,
  "ShortBlockSearch"->shortSearch,
  "PairSpanRank"->pairRank,"Checks"->checks,
  "SupportHistogram"->Counts[Count[#,Except[0]]& /@ b],
  "FinitenessStatus"->"Empirical actual-coefficient cancellation criterion; independent pole proof not supplied",
  "SimplicityStatus"->"Constant integer blocks, shortest available residual extraction; no claim of global sparsity optimum"|>
];
