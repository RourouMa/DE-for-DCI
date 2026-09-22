base=DirectoryName[$InputFileName];Get[FileNameJoin[{base,"IBP4loop.wl"}]];
Get[FileNameJoin[{base,"IBP4IterationTools.wl"}]];
Get[FileNameJoin[{base,"IBP4ShortConstantBasis.wl"}]];
Get[FileNameJoin[{base,"IBP4ConstantDECoefficientBlocks.wl"}]];
campaign=FileNameJoin[{base,"IBP4_from96"}];
root=If[ValueQ[IBP4RunOutputDirectory],IBP4RunOutputDirectory,FileNameJoin[{campaign,"constant_from_top"}]];
If[!DirectoryQ[root],CreateDirectory[root,CreateIntermediateDirectories->True]];
maxPasses=If[ValueQ[IBP4MaxPasses],IBP4MaxPasses,5];
reduction=If[ValueQ[IBP4RunReductionDirectory],IBP4RunReductionDirectory,
 If[FileExistsQ[FileNameJoin[{root,"reduction","IBP4ReductionRules.txt"}]],
 FileNameJoin[{root,"reduction"}],FileNameJoin[{campaign,"factor_first","reduction"}]]];
rules=Get[FileNameJoin[{reduction,"IBP4ReductionRules.txt"}]];
If[!ListQ[rules] || !And@@(MatchQ[#,_Rule]& /@ rules),Print["Incomplete reduction"];Quit[1]];
dr=Dispatch[rules];ruleKeys=First /@ rules;ruleHash=Hash[rules,"SHA256"];
normal[rows_]:=itCanon[(#/.dr)/._G3->0]& /@ rows;
zero[m_]:=And@@Flatten[Map[itZero,m,{2}]];
initialPackageFile=If[ValueQ[IBP4InitialPackageFile],IBP4InitialPackageFile,None];
initialPackage=If[StringQ[initialPackageFile],Get[initialPackageFile],
 <|"Basis"->{G@@TopSectorPowerID},"Definitions"->{},"InputExpanded"->{G@@TopSectorPowerID}|>];
If[!AssociationQ[initialPackage] || !And@@(KeyExistsQ[initialPackage,#]& /@ {"Basis","Definitions","InputExpanded"}),
 Print["Invalid initial finite package"];Quit[1]];
manifest=<|"Start"->If[StringQ[initialPackageFile],"Explicit finite input package","Top integral only"],
 "InitialPackageFile"->initialPackageFile,"InitialPackageHash"->Hash[initialPackage,"SHA256"],
 "ReductionDirectory"->reduction,"RuleHash"->ruleHash,
 "OldBasisFilesRead"->If[StringQ[initialPackageFile],{initialPackageFile},{}],
 "OldDerivativeFilesRead"->{},"EveryTargetSetFreshlyDifferentiated"->True,
 "ConstantCombinationCoefficientsRequired"->True,"SubstituteKnownBlocksBeforeSearching"->True,
 "FactorizedPreferredGaussianOrdering"->Get[FileNameJoin[{reduction,"OrderingSummary.wl"}]],
 "G4QuotientOnly"->True,"CombinationHelperHash"->FileHash[
   FileNameJoin[{base,"IBP4ConstantDECoefficientBlocks.wl"}],"SHA256"],
 "ShortBlockHelperHash"->FileHash[FileNameJoin[{base,"IBP4ShortConstantBasis.wl"}],"SHA256"]|>;
Put[manifest,FileNameJoin[{root,"Manifest.wl"}]];
top=G@@TopSectorPowerID;pkg=initialPackage;
reports=<||>;closed=False;admissionStopped=False;
Do[
 dir=FileNameJoin[{root,"round"<>ToString[k]}];If[!DirectoryQ[dir],CreateDirectory[dir]];
 Print[{"Fresh constant-block pass",k,"Input",Length[pkg["Basis"]]}//InputForm];
 If[!FreeQ[pkg["Definitions"],x|y] || Select[itSupport[pkg["Basis"]],itDiv]=!={},
  Print["Invalid next derivative input: variable coefficients or bare divergence"];Quit[1]];
 der=itDerivatives[pkg,FileNameJoin[{dir,"derivatives"}]];
 needed=itSupport[{pkg["InputExpanded"],der["Dx"],der["Dy"]}];missing=Complement[needed,ruleKeys];
 Put[missing,FileNameJoin[{dir,"MissingRules.wl"}]];
 If[missing=!={},Put[Union[ruleKeys,needed],FileNameJoin[{root,"RequiredRequests.wl"}]];
  Put[<|"Round"->k,"MissingRequestedRules"->Length[missing]|>,FileNameJoin[{root,"Pending.wl"}]];
  Print[{"Need additional reduction rules",k,Length[missing]}//InputForm];Quit[2]];
 targetReductions=normal[der["Targets"]];raw=itSupport[targetReductions];
 input=normal[pkg["InputExpanded"]];de=normal[Join[der["Dx"],der["Dy"]]];
 rows=Join[input,de];div=Select[itSupport[rows],itDiv];c=itCoeff[rows,div];
 safe=SortBy[Select[raw,!itDiv[#]&],{If[itFactor[#],0,1]&,Identity}];
 If[Complement[itSupport[rows],raw]=!={},
  Print["Input or DE requires a representative outside current target reduction"];Quit[1]];
 knownExpressions=normal[Last /@ pkg["Definitions"]];
 known=If[knownExpressions==={},{},itCoeff[knownExpressions,div]];
 known=Select[known,FreeQ[#,x|y] && itZero[Total[#]]&];
 result=ConstantDECoefficientBlocks[c,div,"ConstantRound"<>ToString[k],known];
 If[result===$Failed,Quit[1]];
 defs=result["Definitions"];labels=Join[safe,First /@ defs];expanded=Join[safe,Last /@ defs];
 vars=Join[safe,div];b=itCoeff[expanded,vars];weights=Join[itCoeff[rows,safe],result["Weights"],2];
 n=Length[pkg["Basis"]];rewritten=itCanon /@ (weights.labels);
 checks=Join[result["Checks"],<|
  "ExactInputAndDEReconstruction"->zero[itCoeff[rows,vars]-Normal[SparseArray[weights].SparseArray[b]]],
  "AllNextConstituentsAreCurrentRawMI"->(Complement[itSupport[expanded],raw]==={}),
  "EveryFiniteRawMIRetainedUnchanged"->(Sort[safe]===Sort[Select[raw,!itDiv[#]&]]),
  "NoFiniteSingleInsideCombinations"->And@@(itDiv /@ itSupport[Last /@ defs]),
  "NoBareDivergentNextInput"->(Select[itSupport[labels],itDiv]==={}),
  "NoBareDivergentRewrittenDE"->(Select[itSupport[Drop[rewritten,n]],itDiv]==={}),
  "AllRawRepresentativesInCurrentNormalForm"->And@@(itZero /@ (itCanon /@ (normal[raw]-raw))),
  "RawNonAdjacentLoopISPsNonpositive"->(Max[Flatten[(List@@@raw)[[All,{20,21,22}]]]]<=0),
  "RawLoopLoopPowersAtMostTwo"->(Max[Flatten[(List@@@raw)[[All,17;;22]]]]<=2)|>];
 If[!And@@Values[checks],Put[checks,FileNameJoin[{dir,"FailedChecks.wl"}]];Print[checks//InputForm];Quit[1]];
 ci=itCoeff[input,vars];cd=itCoeff[de,vars];rr=itRR[ci];p=itPiv[rr];
 closureResidual=Map[Together,cd-cd[[All,p]].rr,{2}];
 summary=<|"Pass"->k,"InputCount"->n,"Targets"->Length[der["Targets"]],
  "RawTemporaryMI"->Length[raw],"RawFiniteSingles"->Length[safe],"RawDivergent"->Length[Select[raw,itDiv]],
  "ReducedDESupport"->Length[itSupport[de]],"ReducedDEDivergent"->Length[Select[itSupport[de],itDiv]],
  "SingleFinite"->Length[safe],"FiniteCombinations"->Length[defs],"NextInputCount"->Length[labels],
  "BareDivergent"->0,"XYInsideCombinations"->False,"SupportHistogram"->result["SupportHistogram"],
  "MinimumConstantCombinationCount"->result["ConstantRank"],
  "VariableCoefficientSpanRank"->result["VariableCoefficientRank"],
  "FactorizedFiniteSingles"->Length[Select[safe,itFactor]],
  "ClosedOnCurrentInput"->zero[closureResidual],
  "NonclosedDERows"->Count[closureResidual,row_/;!And@@(itZero /@ row)],
  "FinitenessStatus"->result["FinitenessStatus"],"G4QuotientOnly"->True|>;
 next=<|"Basis"->labels,"Definitions"->defs,"InputExpanded"->expanded,"SingleFinite"->safe,
  "BareDivergent"->{},"Summary"->summary|>;
 If[Length[DownValues[IBP4OutputAdmissionAudit]]>0,
  admission=IBP4OutputAdmissionAudit[next];
  If[!AssociationQ[admission] || !KeyExistsQ[admission,"Accepted"],Print["Invalid finite-output admission audit"];Quit[1]];
  Put[admission,FileNameJoin[{dir,"OutputAdmission.wl"}]];
  admissionStopped=!TrueQ[admission["Accepted"]]];
 Put[next,FileNameJoin[{dir,"NextInput.wl"}]];Put[raw,FileNameJoin[{dir,"RawTemporaryMI.wl"}]];
 Put[targetReductions,FileNameJoin[{dir,"TargetReductionsG4.wl"}]];
 Put[input,FileNameJoin[{dir,"ReducedPreviousInputsG4.wl"}]];Put[de,FileNameJoin[{dir,"ReducedDEG4.wl"}]];
 Put[checks,FileNameJoin[{dir,"Checks.wl"}]];Put[result,FileNameJoin[{dir,"ConstantBlockCertificates.wl"}]];
 Put[summary,FileNameJoin[{dir,"Summary.wl"}]];
 Put[<|"InputBasis"->pkg["Basis"],"OutputBasis"->labels,"InputInOutputBasis"->Take[weights,n],
  "Ax"->Take[Drop[weights,n],n],"Ay"->Drop[weights,2 n],"G3SourceRows"->Missing["NotComputed"]|>,
  FileNameJoin[{dir,"Matrices.wl"}]];
 Put[Drop[rewritten,n],FileNameJoin[{dir,"RewrittenDE.wl"}]];
 Put[<|"Variables"->vars,"Residual"->closureResidual|>,FileNameJoin[{dir,"Closure.wl"}]];
 AssociateTo[reports,ToString[k]->summary];Put[reports,FileNameJoin[{root,"Summary.wl"}]];
 pkg=next;Print[summary//InputForm];closed=summary["ClosedOnCurrentInput"];
 If[admissionStopped,
  Put[<|"Round"->k,"OutputCount"->Length[labels],"Admission"->admission|>,
    FileNameJoin[{root,"PendingFiniteValidation.wl"}]];
  Print[{"Next differentiation withheld: finite-output admission failed",k,admission["UnverifiedLabels"]}//InputForm];Break[]];
 If[closed && TrueQ[IBP4StopWhenClosed],Break[]],{k,maxPasses}];
Put[<|"CompletedPasses"->Length[reports],"LastOutputDifferentiated"->False,"AllTargetsRegenerated"->True,
 "ClosedOnLastInput"->closed,
 "EveryPassedInputHadConstantCombinations"->True,"StoppedBeforeUnverifiedFiniteInput"->admissionStopped,
 "RuleHash"->ruleHash|>,FileNameJoin[{root,"Completion.wl"}]];
If[!admissionStopped && FileExistsQ[FileNameJoin[{root,"PendingFiniteValidation.wl"}]],
 DeleteFile[FileNameJoin[{root,"PendingFiniteValidation.wl"}]]];
If[FileExistsQ[FileNameJoin[{root,"Pending.wl"}]],DeleteFile[FileNameJoin[{root,"Pending.wl"}]]];
Quit[];
