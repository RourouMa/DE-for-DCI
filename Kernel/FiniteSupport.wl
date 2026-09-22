linearMapNoExpand[e_]:=Module[{walk,terms,result,const,tag=Unique[]},
 walk[z_]:=Which[
  MatchQ[z,_G|_BoundaryIntegral],{z->1},
  FreeQ[z,_G|_BoundaryIntegral],If[TrueQ[z===0],{},{0->z}],
  Head[z]===Plus,Flatten[walk /@ (List@@z)],
  Head[z]===Times,With[{factors=List@@z},With[{integralFactors=Select[factors,!FreeQ[#,_G|_BoundaryIntegral]&],scalarFactors=Select[factors,FreeQ[#,_G|_BoundaryIntegral]&]},
   If[Length[integralFactors]=!=1,Throw[Failure["Nonlinear",<||>],tag]];With[{scale=Times@@scalarFactors},(First[#]->scale Last[#])& /@ walk[First[integralFactors]]]]],
  True,Throw[Failure["Nonlinear",<||>],tag]];
 terms=Catch[walk[e],tag];If[FailureQ[terms],Return[terms]];
 result=Merge[Association /@ terms,Total];const=Lookup[result,0,0];If[!TrueQ[Together[const]===0],Return[Failure["Constant",<||>]]];KeyDrop[result,0]];
directFiniteSupport[rows_List,gs_List]:=Module[{maps,w,boundary},
 maps=linearMapNoExpand /@ rows;If[AnyTrue[maps,FailureQ],Return[First[Select[maps,FailureQ]]]];
 w=Lookup[#,gs,0]& /@ maps;
 boundary=Total[KeyValueMap[If[MatchQ[#1,_BoundaryIntegral],#2 #1,0]&,#]]& /@ maps;
 <|"Basis"->gs,"SingleFinite"->gs,"Combinations"->{},"Weights"->w,"BoundaryRows"->boundary,
 "ConstantCombinationRank"->0,"ExactCoverage"->True,"NoKinematicsInCombinations"->True,
 "MinimumCountForActualConstantSpan"->False,"GlobalSparsityOptimumClaimed"->False,
 "CoverageMethod"->"Exact partition of linear coefficient maps; every G atom individually finite",
 "FiniteCoverSearchSkipped"->True,"FinitenessCriterion"->"Each remaining G passes FiniteIntegralQ"|>];
