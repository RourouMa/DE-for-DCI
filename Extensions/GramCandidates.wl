(* Optional dimension-specific candidate pool; never silently merged into IBP. *)
BeginPackage["ConformalGramCandidates`",{"ConformalIBP`"}];
GramCandidatePolynomials::usage="GramCandidatePolynomials[family] constructs rank-(D+2) Gram minors with provenance and exact loop degrees.";
GenerateGramCandidateRelations::usage="GenerateGramCandidateRelations[family,centers,polynomials] returns separately tagged, domain-checked linear candidates.";
Begin["`Private`"];
Options[GramCandidatePolynomials]={"IncludeMixedMinors"->False};
GramCandidatePolynomials[f_Association,OptionsPattern[]]:=Module[{v=Join[f["External"],f["Loops"]],dim=f["Dimension"]+2,sets,pairs,m,result={},poly,terms,degree,actual,failure=None},
 If[Length[v]<=dim,Return[{}]];sets=Subsets[Range[Length[v]],{dim+1}];
 pairs=If[TrueQ[OptionValue["IncludeMixedMinors"]],Flatten[Table[{sets[[i]],sets[[j]]},{i,Length[sets]},{j,i,Length[sets]}],1],{#,#}& /@ sets];
 m=Table[SP[a,b],{a,v},{b,v}]/.ConformalIBP`Private`scalarRules[f];
 Do[poly=Expand[Det[m[[pair[[1]],pair[[2]]]]]];If[poly===0,Continue[]];terms=CoefficientRules[poly,f["Propagators"]];
 degree=Table[Count[v[[pair[[1]]]],y]+Count[v[[pair[[2]]]],y],{y,f["Loops"]}];
 actual=Union[ConformalIBP`Private`weights[f,First[#]]& /@ terms];
 If[actual=!={degree},failure=Failure["GramDegree",<|"Pair"->pair,"Expected"->degree,"Actual"->actual|>];Break[]];
 AppendTo[result,<|"FamilyHash"->f["Hash"],"EmbeddingDimension"->dim,"Rows"->pair[[1]],"Columns"->pair[[2]],"LoopDegree"->degree,"Terms"->terms,"Polynomial"->poly,"Proof"->"Every (D+3)-minor of V.metric.Transpose[V] vanishes in embedding dimension D+2","DimensionSpecific"->True|>],{pair,pairs}];If[FailureQ[failure],failure,result]];
Options[GenerateGramCandidateRelations]={"MaxSeedsPerCenter"->1,"ProgressFunction"->None};
GenerateGramCandidateRelations[f_Association,centers_List,polynomials_List,OptionsPattern[]]:=Module[{gs=ConformalIBP`Private`support[centers],limit=OptionValue["MaxSeedsPerCenter"],report=OptionValue["ProgressFunction"],records={},seen=<||>,powers,cs,candidates,atoms,expr,h,n=0,accepted,a,deg,tag=Unique["gramFailure"]},Catch[
 If[!IntegerQ[limit] || limit<1,Throw[Failure["SeedLimit",<||>],tag]];
 If[!And@@(#["FamilyHash"]===f["Hash"]& /@ polynomials),Throw[Failure["FamilyMismatch",<||>],tag]];
 Do[powers=First /@ poly["Terms"];cs=Last /@ poly["Terms"];deg=poly["LoopDegree"];
 Do[a=Take[List@@g,Length[f["Propagators"]]];If[ConformalIBP`Private`weights[f,a]=!=ConstantArray[4,f["LoopCount"]],Continue[]];
 candidates=SortBy[Union[(a+#)& /@ powers],{Total[Abs[#]]&,Identity}];accepted=0;
 Do[If[!And@@Thread[(seed-(Min /@ Transpose[powers]))[[f["LoopLoopIDs"]]]<=f["MaxLoopPower"]],Continue[]];
 atoms=G@@Join[seed-#,ConstantArray[1,f["LoopCount"]]]& /@ powers;
 If[!And@@(ConformalIBP`Private`domainQ[f,#]& /@ atoms),Continue[]];
 expr=ConformalIBP`Private`canonExpr[f,cs.atoms];If[FailureQ[expr],Throw[expr,tag]];If[ConformalIBP`Private`zero[expr],Continue[]];
 h=Hash[expr,"SHA256"];If[!KeyExistsQ[seen,h],AssociateTo[seen,h->True];AppendTo[records,<|"Kind"->"EmbeddingGram","FamilyHash"->f["Hash"],"Dimension"->f["Dimension"],"MinorRows"->poly["Rows"],"MinorColumns"->poly["Columns"],"Center"->g,"MultiplierPowers"->seed,"LoopDegree"->deg,"Relation"->expr,"RelationHash"->h,"AllTermsConformalAndInDomain"->And@@(ConformalIBP`Private`domainQ[f,#] && ConformalIBP`Private`weights[f,List@@#]===ConstantArray[4,f["LoopCount"]]& /@ ConformalIBP`Private`support[expr]),"Status"->"Candidate; target benefit not yet certified"|>]];
 accepted++;If[accepted>=limit,Break[]],{seed,candidates}];n++;If[report=!=None,report[<|"CenterMinorPairs"->n,"CandidateRelations"->Length[records]|>]],{g,gs}],{poly,polynomials}];
 <|"FamilyHash"->f["Hash"],"Candidates"->records,"Equations"->(#["Relation"]& /@ records),"CompleteSeedEnumeration"->False,"MaxSeedsPerCenter"->limit,"AutomaticallyMerged"->False|>,tag]];
End[];EndPackage[];
