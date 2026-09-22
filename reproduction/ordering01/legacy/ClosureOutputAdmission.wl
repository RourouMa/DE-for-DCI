Get[FileNameJoin[{DirectoryName[$InputFileName],"CollisionResidueSymmetry.wl"}]];
IBP4OutputAdmissionAudit[package_Association]:=Module[{defs=package["Definitions"],records,unsupported,res},
 records=Table[
  unsupported=Select[itSupport[Last[def]],Count[(List@@#)[[17;;22]],2]>1&];
  res=If[unsupported==={},crResidue[Last[def]],Missing["OverlappingPoleAnalysisRequired"]];
  <|"Label"->First[def],"CollisionResidue"->res,"SinglePoleConstituents"->(unsupported==={}),
    "Accepted"->(unsupported==={} && res===0)|>,{def,defs}];
 <|"Accepted"->And@@Lookup[records,"Accepted",{}],"CombinationChecks"->records,
  "UnverifiedLabels"->Lookup[Select[records,!TrueQ[#["Accepted"]]&],"Label",{}],
  "Criterion"->"Single-double-pole residues cancel modulo exact loop and factor relabelings",
  "NonzeroMayRequireLowerLoopIBP"->True,"NotAFullConvergenceProof"->True|>];
