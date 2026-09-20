(* Read saved results only. No generation, reduction, or checkpoint modification. *)
reportArgs=If[Length[$ScriptCommandLine]>=2,$ScriptCommandLine,$CommandLine];
reportDir=ExpandFileName[Last[reportArgs]];
reportPackage=FileNameJoin[{reportDir,"source","Kernel","ConformalIBP.wl"}];
If[!FileExistsQ[reportPackage],Print["A campaign with its frozen source/Kernel is required."];Quit[1]];
Get[reportPackage];
reportFiles=Select[FileNames["Summary.wl",reportDir,3],
 StringMatchQ[FileNameTake[DirectoryName[#]],"round"~~DigitCharacter..] &&
 StringMatchQ[FileNameTake[DirectoryName[DirectoryName[#]]],"epoch"~~DigitCharacter..]&];
reportRows=Table[
 reportPath=DirectoryName[file];reportSummary=Get[file];
 reportFinite=Get[FileNameJoin[{reportPath,"FiniteBasis.wl"}]];
 reportReduction=Get[FileNameJoin[{reportPath,"Reduction.wl"}]];
 Join[<|"Epoch"->ToExpression[StringDrop[FileNameTake[DirectoryName[reportPath]],5]]|>,reportSummary,
  <|"ReductionColumns"->reportReduction["Columns"],"ReductionEquations"->reportReduction["EquationCount"],
  "ExactEquationResidualsZero"->reportReduction["ExactEquationResidualsZero"],
  "Idempotent"->reportReduction["Idempotent"],
  "SelfReducedQueries"->Length[reportReduction["SelfReducedTargets"]],
  "UnseenQueries"->Length[reportReduction["UnseenTargets"]],
  "ExactFiniteCoverage"->reportFinite["ExactCoverage"],
  "ConstantCombinationRank"->reportFinite["ConstantCombinationRank"],
  "NoKinematicsInCombinations"->reportFinite["NoKinematicsInCombinations"],
  "EvidenceDirectory"->reportPath|>],{file,reportFiles}];
reportRows=SortBy[reportRows,{#["Epoch"],#["Round"]}&];
Export[FileNameJoin[{reportDir,"CompletedRounds.json"}],reportRows,"RawJSON"];
Print[<|"CompletedRoundRecords"->Length[reportRows],"Output"->FileNameJoin[{reportDir,"CompletedRounds.json"}]|>];
Quit[0];
