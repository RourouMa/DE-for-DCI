(* ::Package:: *)

(* Four-loop ladder-family syzygy IBP generator.

   This file is adapted from the three-loop tennis-court workflow in
   IBP3loop.wl.  The main changes are:

   1. the loop number is promoted to LoopNumber = 4;
   2. propagator indices, top-sector data, UV/IR power-counting vectors,
      and delta-cut indices are generated from the family definition;
   3. the default four-loop ladder family has 13 denominator propagators plus
      4 delta-cut propagators.  It is not the complete set of all X_a.Y_i
      propagators.  Scalar products outside the 13 denominators are kept as
      ISP numerator slots and appear as negative entries in G[...].
      The optional temporary super-family mode promotes missing loop-loop
      edges from ISP slots to denominator slots only when one deliberately
      searches super-sector seeds;
   4. the IBP system is generated sector by sector, as in the three-loop
      code, and writes one file per sector and syzygy block.

   Usage outline in Mathematica:

      Get["/path/to/IBP4loop.wl"];
      targetInt = {G @@ TopSectorPowerID};
      IBP4 = IBPSystem[DefaultSyzygyBlocks, targetInt,
        "OutputDirectory" -> "/path/to/IBP4_ladder_seed"];

   For a temporary super-sector seeding run:

      IncludeSuperSectorEdges = True;
      Get["/path/to/IBP4loop.wl"];

   The finite-field reduction and differential-equation closure steps should
   consume the generated IBP relations iteratively, following DEtennis.wl.
*)

If[! ValueQ[TemporaryDirectory], TemporaryDirectory = $HomeDirectory <> "/exchange/"];
If[! ValueQ[SingularDirectory],
  SingularDirectory = SelectFirst[
    {"/usr/bin/Singular", "/opt/homebrew/bin/Singular", "/usr/local/bin/Singular"},
    FileExistsQ,
    "Singular"
  ]
];
If[! ValueQ[SingularInterfacePath],
  SingularInterfacePath = $HomeDirectory <> "/Packages/SingularInterface/Singular.m"
];

If[FileExistsQ[SingularInterfacePath], Get[SingularInterfacePath],
  Print["Warning: Singular interface was not found at ", SingularInterfacePath,
    ".  Set SingularInterfacePath before calling SingularSyz."]
];

SetAttributes[sp, Orderless];

(* ::Section:: *)
(*Family Data*)

LoopNumber = 4;
EmbeddingDimension = 6;
ExternalVars = {X1, X2, X3, X4};
LoopVars = {Y1, Y2, Y3, Y4};
vectorList = v /@ Join[ExternalVars, LoopVars];
integrateVar = LoopVars;

(* Default four-loop ladder: 13 denominator propagators inside a fixed
   22-slot non-delta scalar-product basis.

   The three-loop ladder sector convention used for the four-loop lift is
      {1,1,0,1, 0,1,0,1, 0,1,1,1, 1,1,0},
   namely
      X1.Y1, X2.Y1, X4.Y1,
      X2.Y2, X4.Y2,
      X2.Y3, X3.Y3, X4.Y3,
      Y1.Y2, Y2.Y3.
   This is the one-step external-label rotation of the earlier local
   convention in which X1,X2,X3 appeared on the left box.

   The four-loop full non-delta ordering used here is
      D1..D16  = Xa.Yi, grouped by Yi and then Xa,
      D17..D19 = adjacent ladder edges Y1.Y2, Y2.Y3, Y3.Y4,
      D20..D22 = non-adjacent loop-loop ISP/super-sector slots.

   The denominator IDs of the four-loop ladder are
      {1,2,4,6,8,10,12,14,15,16,17,18,19}.
   The remaining non-delta slots are ISP numerator slots, whose powers may
   become negative in G[...].

   Set IncludeSuperSectorEdges=True before loading this file only for a
   temporary super-sector seeding run.  This promotes D20..D22 to denominator
   slots for sector selection, but the G-ordering remains unchanged. *)
If[! ValueQ[IncludeSuperSectorEdges], IncludeSuperSectorEdges = False];
If[! ValueQ[VerboseIBPWarnings], VerboseIBPWarnings = False];

AllExternalLoopPairs =
  Flatten[Table[{aa, ii}, {ii, LoopNumber}, {aa, Length[ExternalVars]}], 1];
AllExternalLoopScalarProducts =
  sp[ExternalVars[[#[[1]]]], LoopVars[[#[[2]]]]] & /@ AllExternalLoopPairs;

AdjacentLoopEdges = Partition[Range[LoopNumber], 2, 1];
NonAdjacentLoopEdges = Complement[Subsets[Range[LoopNumber], {2}], AdjacentLoopEdges];
AllLoopLoopScalarProducts =
  sp[LoopVars[[#[[1]]]], LoopVars[[#[[2]]]]] & /@
    Join[AdjacentLoopEdges, NonAdjacentLoopEdges];

Propagators = Join[AllExternalLoopScalarProducts, AllLoopLoopScalarProducts];
DeltaPropagators = sp[#, #] & /@ LoopVars;
Propagators4 = Join[Propagators, DeltaPropagators];

PropagatorIndexRules = Thread[Range[Length[Propagators4]] -> Propagators4];
PropagatorLoopSupport = Join[
  AllExternalLoopPairs[[All, 2]] /. ii_Integer :> {ii},
  Join[AdjacentLoopEdges, NonAdjacentLoopEdges]
];

LadderDenominatorSector =
  {1, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0};
DenominatorPropagatorIDs = Flatten[Position[LadderDenominatorSector, 1]];
If[TrueQ[IncludeSuperSectorEdges],
  DenominatorPropagatorIDs = Union[DenominatorPropagatorIDs, {20, 21, 22}]
];
ISPPropagatorIDs = Complement[Range[Length[Propagators]], DenominatorPropagatorIDs];
ISPPropagators = Propagators[[ISPPropagatorIDs]];
LoopLoopPropagatorIDs = {17, 18, 19};
DeltaPropagatorIDs = Range[Length[Propagators] + 1, Length[Propagators4]];

TopSectorPowerID = Join[
  LadderDenominatorSector,
  ConstantArray[1, LoopNumber]
];
TopSectorNoDelta =
  TopSectorPowerID[[;; Length[Propagators]]];

Kinematics = {
  sp[X1, X3] -> x^2 + 1,
  sp[X2, X4] -> y^2 + 1,
  sp[X1, X1] -> 2 x,
  sp[X2, X2] -> 2 y,
  sp[X3, X3] -> 2 x,
  sp[X4, X4] -> 2 y,
  sp[X1, X2] -> 0,
  sp[X2, X3] -> 0,
  sp[X3, X4] -> 0,
  sp[X1, X4] -> 0
};

(* External differential operators used later for the DE construction. *)
DOperatorx =
  1/((x - 1) (x + 1)) (x v[X1] d[X1] + x v[X3] d[X3] -
    v[X1] d[X3] - v[X3] d[X1]);

DOperatory =
  1/((y - 1) (y + 1)) (y v[X2] d[X2] + y v[X4] d[X4] -
    v[X2] d[X4] - v[X4] d[X2]);

(* ::Section:: *)
(*Power Counting*)

LoopSubsetList = Rest[Subsets[Range[LoopNumber]]];

LoopEndpointMultiplicity[id_Integer, subset_List] := Module[{edge},
  edge = PropagatorLoopSupport[[id]];
  Count[MemberQ[subset, #] & /@ edge, True]
];

UVRegionVector[subset_List] :=
  Table[LoopEndpointMultiplicity[id, subset],
    {id, Length[PropagatorLoopSupport]}];

IRRegionVector[subset_List] :=
  Table[If[Length[PropagatorLoopSupport[[id]]] == 1, 0,
    LoopEndpointMultiplicity[id, subset]],
    {id, Length[PropagatorLoopSupport]}];

UVRegionAssociation = Association[(# -> UVRegionVector[#]) & /@ LoopSubsetList];
IRRegionAssociation = Association[(# -> IRRegionVector[#]) & /@ LoopSubsetList];

FiniteIntQ[inte_] := Module[{powerID},
  powerID = List @@ inte[[;; -LoopNumber - 1]];
  And @@ Join[
    Table[powerID . UVRegionAssociation[subset] == 4 Length[subset],
      {subset, LoopSubsetList}],
    Table[powerID . IRRegionAssociation[subset] < 4 Length[subset],
      {subset, LoopSubsetList}]
  ]
];

LoopScaleFactor[expr_] := Module[{pos},
  pos = FirstPosition[LoopVars, expr, Missing["NotLoop"]];
  If[pos === Missing["NotLoop"], 1, c[pos[[1]]]]
];

ScaleLoopExpr[expr_] := expr /. {
  d[xx_] :> LoopScaleFactor[xx] d[xx],
  v[xx_] :> LoopScaleFactor[xx] v[xx],
  sp[xx_, yy_] :> LoopScaleFactor[xx] LoopScaleFactor[yy] sp[xx, yy]
};

HomogeneousQ[IBPOperator_] := Module[{dlist, dcoef, rescaling, powerList, cvars},
  dlist = Select[Variables[IBPOperator], Head[#] == d &];
  dcoef = Coefficient[IBPOperator, #] & /@ dlist;
  cvars = Array[c, LoopNumber];
  rescaling = ScaleLoopExpr[((1/dlist) dcoef)] // Factor;
  powerList = MapThread[{#1[[1, 1]], #2[[1, 1]]} &,
    {CoefficientRules[Denominator[rescaling], cvars],
     CoefficientRules[Numerator[rescaling], cvars]}] // Union;
  If[Length[powerList] == 1, powerList[[1, 1]] - powerList[[1, 2]], False]
];

(* ::Section:: *)
(*Syzygy IBP Operators*)

Dsp[spExp_, var_] := Expand[
  D[spExp, var] /. {
    Derivative[0, 1][sp][x1_, x2_] :> D[x2, var] v[x1],
    Derivative[1, 0][sp][x1_, x2_] :> D[x1, var] v[x2],
    Derivative[1][v][xx_] :> EmbeddingDimension D[xx, var]
  }] /. {v[xx_] v[yy_] :> sp[xx, yy], v[xx_]^2 :> sp[xx, xx]};

syzygyOriginal[syzygyProp_, bList_, intVar_, vecList_] :=
  (Collect[
      Expand[(Table[a[ii, jj], {ii, Length[intVar]}, {jj, Length[vecList]}] .
          vecList) .
        Table[Dsp[syzygyProp[[#]], intVar[[ii]]], {ii, Length[intVar]}]] /.
        {v[xx_] v[yy_] :> sp[xx, yy], v[xx_]^2 :> sp[xx, xx]},
      Head[#] == sp &] - bList[[#]] syzygyProp[[#]]) & /@
    Range[Length[syzygyProp]];

syzygyMatrix[deltaProp_, divProp_, intVar_, vecList_] := Module[
  {syzygyProp, syzygyID, bList, mat},
  syzygyProp = Join[deltaProp[[1]], divProp[[1]]];
  syzygyID = Join[deltaProp[[2]], divProp[[2]]];
  bList = b /@ syzygyID;
  mat = CoefficientArrays[
      syzygyOriginal[syzygyProp, bList, intVar, vecList],
      Join[Table[a[ii, jj], {ii, Length[intVar]}, {jj, Length[vecList]}] //
        Flatten, bList]][[2]] // Normal;
  {mat, Join[d /@ intVar, pro @@@ bList]}
];

Syz2IBPOperator[syzSlu_, intVar_, vecList_, operatorBas_] := Module[
  {dirPartEle, dirPart},
  dirPartEle = Length[intVar] Length[vecList];
  dirPart = ArrayReshape[syzSlu[[;; dirPartEle]],
      {Length[intVar], Length[vecList]}] . vecList;
  Join[dirPart, syzSlu[[dirPartEle + 1 ;;]]] . operatorBas
];

BuildSyzygyOperatorBlock[protectedLoopLoopIDs_List : {}] := Module[
  {deltaData, divData, matrixData, syz, opPre, op, operatorDegList,
   operatorDegListTypeAll},
  deltaData = {DeltaPropagators, DeltaPropagatorIDs};
  divData = {Propagators4[[protectedLoopLoopIDs]], protectedLoopLoopIDs};
  matrixData = syzygyMatrix[deltaData, divData, integrateVar, vectorList];
  syz = SingularSyz[matrixData[[1]] // Transpose, Propagators4];
  opPre = (Syz2IBPOperator[#, integrateVar, vectorList, matrixData[[2]]] & /@ syz)[[LoopNumber + 1 ;;]];
  op = Select[opPre,
    Length[Intersection[Variables[#], DeltaPropagators]] == 0 &];
  operatorDegList = HomogeneousQ[# /. pro[_] :> 0] & /@ op;
  operatorDegListTypeAll = DeleteCases[Union[HomogeneousQ[#] & /@ op], False];
  {op[[Flatten[Position[operatorDegList, #]]]] & /@
      operatorDegListTypeAll, operatorDegListTypeAll}
];

(* Delta-only syzygies are the default.  Additional blocks can be generated
   by protecting one or several loop-loop propagators, e.g.
      BuildSyzygyOperatorBlock[{17}]
   in the adjacent-edge ladder family. *)
DefaultSyzygyBlocks := {BuildSyzygyOperatorBlock[]};

ProtectedLoopLoopSyzygyBlocks[] :=
  BuildSyzygyOperatorBlock /@ Subsets[LoopLoopPropagatorIDs, {1, Length[LoopLoopPropagatorIDs]}];

(* ::Section:: *)
(*IBP Relations*)

DeltaDenominator[] := Times @@ DeltaPropagators;

ToLowerLoop[dotInd_, sqtList_, IBPOperator_, integrand_] := Module[
  {derivativeVar, dcoef, candidateVar, dID},
  derivativeVar = Select[Variables[IBPOperator], Head[#] == d &];
  dcoef = Coefficient[IBPOperator, #] & /@ derivativeVar;
  candidateVar = List @@ sqtList[[dotInd[[2]]]];
  Sum[
    Dsp[integrand (dcoef[[dID]]) // Factor, derivativeVar[[dID, 1]]] -
      If[MemberQ[candidateVar, derivativeVar[[dID, 1]]],
       2 (Factor[sqtList[[dotInd[[2]]]]^2 integrand (dcoef[[dID]])]/
          sp[inf, derivativeVar[[dID, 1]]] /. v[exp_] :> sp[inf, exp] /.
          {candidateVar[[2]] -> candidateVar[[1]]}), 0],
    {dID, Length[derivativeVar]}]
];

ToIBPRep[IBPOperator_, integrand_] := Module[{derivativeVar, dcoef, dID},
  derivativeVar = Select[Variables[IBPOperator], Head[#] == d &];
  dcoef = Coefficient[IBPOperator, #] & /@ derivativeVar;
  Sum[Dsp[integrand (dcoef[[dID]]), derivativeVar[[dID, 1]]],
    {dID, Length[derivativeVar]}]
];

LowerLoopRelated[IBPOperator_, propagator_, intTarget_] := Module[
  {intProp, IBPexp, denominatorTerm, numeratorTerm, mixTerms, lowerLoopList,
   integrandList, lowerIntegrandList, remainList, lowerLoopPart, remainPart},
  intProp = List @@ intTarget;
  IBPexp = 1/Inner[Power,
      propagator[[;; Length[Propagators]]],
      intProp[[;; Length[Propagators]]], Times]
    IBPOperator // Factor;
  denominatorTerm = CoefficientRules[Denominator[IBPexp], propagator];
  numeratorTerm = CoefficientRules[Numerator[IBPexp], propagator];
  mixTerms = (#[[1]] - denominatorTerm[[1, 1]]) ->
      (#[[2]]/denominatorTerm[[1, 2]]) & /@ numeratorTerm;
  integrandList = Inner[Power, propagator, #, Times] & /@ (mixTerms[[All, 1]]);
  lowerLoopList = Position[mixTerms[[All, 1, LoopLoopPropagatorIDs]], -2];
  (* A collision boundary contributes only to derivatives of its endpoints. *)
  lowerLoopList = Select[lowerLoopList, Function[pos,
    Intersection[List @@ Propagators[[LoopLoopPropagatorIDs[[pos[[2]]]]]],
      First /@ Select[Variables[mixTerms[[pos[[1]], 2]]], Head[#] === d &]] =!= {}]];
  If[Length[lowerLoopList] == 0, Return[
    Total[MapThread[1/DeltaDenominator[] ToIBPRep[#1, #2] &,
      {mixTerms[[All, 2]], integrandList}]]
  ]];
  If[Length[lowerLoopList[[All, 1]]] > Length[Union[lowerLoopList[[All, 1]]]],
    If[TrueQ[VerboseIBPWarnings],
      Print["Warning: more than one double loop-loop pole appeared in one term: ",
        {IBPOperator, intTarget}]
    ];
    Return[False]
  ];
  lowerIntegrandList = integrandList[[lowerLoopList[[All, 1]]]];
  remainList = Complement[Range[Length[mixTerms]], lowerLoopList[[All, 1]]];
  lowerLoopPart = MapThread[
      1/DeltaDenominator[] ToLowerLoop[#1, Propagators[[LoopLoopPropagatorIDs]],
        #2, #3] &,
      {lowerLoopList, mixTerms[[All, 2]][[lowerLoopList[[All, 1]]]],
       lowerIntegrandList}] // Total;
  remainPart = If[remainList === {}, 0,
    MapThread[1/DeltaDenominator[] ToIBPRep[#1, #2] &,
      {mixTerms[[All, 2]][[remainList]], integrandList[[remainList]]}] //
      Total];
  lowerLoopPart + remainPart
];

Operator2IBPRat[IBPOperator_, propagator_, intTarget_] := Module[
  {intProp, prolist, procoef, deltaPart, lowerLoopQ},
  intProp = List @@ intTarget;
  prolist = Intersection[Select[Variables[IBPOperator], Head[#] == pro &],
    pro /@ DeltaPropagatorIDs];
  procoef = Coefficient[IBPOperator, #, 1] & /@ prolist;
  deltaPart = If[prolist === {}, 0,
    1/Inner[Power, propagator, intProp, Times]
      Total[MapThread[-intProp[[#1]] procoef[[#2]] &,
        {prolist[[All, 1]], Range[Length[prolist[[All, 1]]]]}]]
  ];
  lowerLoopQ = LowerLoopRelated[IBPOperator, propagator, intTarget];
  If[lowerLoopQ === False, 0, deltaPart + lowerLoopQ // Factor]
];

spInt2PowerIDInt[expr_, propagator_] := Module[
  {denominator, numerator, mix},
  If[expr === 0, Return[0]];
  denominator = CoefficientRules[Denominator[expr], propagator];
  numerator = CoefficientRules[Numerator[expr], propagator];
  mix = (denominator[[1, 1]] - #[[1]]) ->
      (#[[2]]/denominator[[1, 2]]) & /@ numerator;
  MapThread[#1 #2 &, {G @@@ (mix[[All, 1]]), mix[[All, 2]]}] // Total
];

LowerLoopToG3Rules = {
  G[0, 0, 0, 0, n5_, n6_, n7_, n8_, n9_, n10_, n11_, n12_,
    n13_, n14_, n15_, n16_, 0, n18_, n19_, 0, 0, n22_,
    n23_, n24_, n25_, n26_] :>
    G3[n5, n6, n7, n8, n9, n10, n11, n12, n13, n14, n15, n16,
      n18, n19, n22, n24, n25, n26],

  G[n1_, n2_, n3_, n4_, 0, 0, 0, 0, n9_, n10_, n11_, n12_,
    n13_, n14_, n15_, n16_, 0, 0, n19_, n20_, n21_, 0,
    n23_, n24_, n25_, n26_] :>
    G3[n1, n2, n3, n4, n9, n10, n11, n12, n13, n14, n15, n16,
      n20, n19, n21, n23, n25, n26],

  G[n1_, n2_, n3_, n4_, n5_, n6_, n7_, n8_, 0, 0, 0, 0,
    n13_, n14_, n15_, n16_, n17_, 0, 0, 0, n21_, n22_,
    n23_, n24_, n25_, n26_] :>
    G3[n1, n2, n3, n4, n5, n6, n7, n8, n13, n14, n15, n16,
      n17, n22, n21, n23, n24, n26],

  G[n1_, n2_, n3_, n4_, n5_, n6_, n7_, n8_, n9_, n10_, n11_, n12_,
    0, 0, 0, 0, n17_, n18_, 0, n20_, 0, 0,
    n23_, n24_, n25_, n26_] :>
    G3[n1, n2, n3, n4, n5, n6, n7, n8, n9, n10, n11, n12,
      n17, n18, n20, n23, n24, n25]
};

DropBadDeltaIntegrals[expr_] :=
  expr /. LowerLoopToG3Rules /. G[pre___, n1_, n2_, n3_, n4_] :>
    If[Min[{n1, n2, n3, n4}] <= 0, 0, G[pre, n1, n2, n3, n4]];

Operator2IBP[IBPOperator_, propagator_, intTarget_] := Module[
  {IBPOriginal, IBPRelation, finiteCheck, conformalCheck},
  IBPOriginal = Operator2IBPRat[IBPOperator, propagator, intTarget];
  IBPRelation = DropBadDeltaIntegrals[spInt2PowerIDInt[IBPOriginal, propagator] /.
      Kinematics];
  finiteCheck = Position[
      Union[FiniteIntQ[#] & /@ Select[Variables[IBPRelation], Head[#] == G &]],
      False] === {};
  conformalCheck = Select[Variables[IBPRelation], Head[#] == sp &] === {};
  If[finiteCheck && conformalCheck, IBPRelation, False]
];

(* ::Section:: *)
(*Sector Seeds and IBP System*)

Sector[idList_] := If[# > 0, 1, 0] & /@ idList;
SectorID[idList_] := FromDigits[Sector[idList], 2];
MaxProp[idList_] := Max[Abs[idList]];
SectorNum[idList_] := Length[Cases[Sector[idList], 1]];
SeedRange[targetList_, propNum_] := MinMax[targetList[[All, #]]] & /@ Range[propNum];

SeedInt[seedPre_, operatorDeg_, powerID_] := Module[{constraints, target, seedInt},
  constraints = Join[
    seedPre,
    Table[powerID . UVRegionAssociation[subset] ==
        4 Length[subset] - Total[operatorDeg[[subset]]],
      {subset, LoopSubsetList}],
    Table[powerID . IRRegionAssociation[subset] <
        4 Length[subset] - Total[operatorDeg[[subset]]],
      {subset, LoopSubsetList}]
  ];
  target = Reduce[constraints, powerID, Integers];
  target = If[target === False, {}, If[Head[target] === Or, List @@ target, {target}]];
  seedInt = G @@ Join[(List @@ #)[[All, 2]], ConstantArray[1, LoopNumber]] & /@ target
];

SeedAdmissibleQ[powerVector_, operatorDeg_] :=
  And @@ Join[
    Table[powerVector . UVRegionAssociation[subset] ==
        4 Length[subset] - Total[operatorDeg[[subset]]],
      {subset, LoopSubsetList}],
    Table[powerVector . IRRegionAssociation[subset] <
        4 Length[subset] - Total[operatorDeg[[subset]]],
      {subset, LoopSubsetList}]
  ];

TargetOnlySeedInt[targetVectors_, operatorDeg_] :=
  G @@ Join[#, ConstantArray[1, LoopNumber]] & /@
    Select[targetVectors, SeedAdmissibleQ[#, operatorDeg] &];

Options[IBPSystem] = {
  "OutputDirectory" -> FileNameJoin[{Directory[], "IBP4_ladder_output"}],
  "SeedBounds" -> Automatic,
  "SeedMode" -> "PowerCounting",
  "CleanFalseRelations" -> True
};

IBPSystem[syzygyBlocks_, targetInt_, OptionsPattern[]] := Module[
  {flag, propNum, targetNoDelta, sectorVectors, sectorIDList, leadingSector,
   leadingSectorBits, leadingTarget, seedPre, powerID, seedInt, parallelID,
   IBPRelation, IBPSet, badID, outputDir, syzygyID, operatorBlocks,
   degreeBlocks},

  outputDir = OptionValue["OutputDirectory"];
  If[! DirectoryQ[outputDir], CreateDirectory[outputDir, CreateIntermediateDirectories -> True]];
  targetNoDelta =
    (List @@@ targetInt)[[All, ;; Length[Propagators]]];
  propNum = Length[targetNoDelta[[1]]];
  powerID = x /@ Range[propNum];
  flag = 0;

  operatorBlocks = syzygyBlocks[[All, 1]];
  degreeBlocks = syzygyBlocks[[All, 2]];

  While[targetNoDelta =!= {},
    sectorVectors = targetNoDelta[[All, ;; Length[Propagators]]];
    sectorIDList = {SectorNum[#], SectorID[#]} & /@ sectorVectors;
    leadingSector = MaximalBy[sectorIDList, First, 1][[1]];
    leadingSectorBits = Join[
      ConstantArray[0, Length[Propagators] -
        Length[IntegerDigits[leadingSector[[2]], 2]]],
      IntegerDigits[leadingSector[[2]], 2]];
    Print["Start sector ", leadingSectorBits, ", ", leadingSector[[1]],
      " propagators, remain ", Length[Union[sectorIDList]] - 1, " sectors ..."];
    leadingTarget = targetNoDelta[[Flatten[Position[sectorIDList, leadingSector]]]];

    Do[
      seedPre = If[OptionValue["SeedBounds"] === Automatic,
        MapThread[#1 <= #2 <= #3 &,
          {SeedRange[leadingTarget, propNum][[All, 1]], powerID,
           SeedRange[leadingTarget, propNum][[All, 2]]}],
        OptionValue["SeedBounds"]
      ];
      seedInt = ParallelTable[
        If[OptionValue["SeedMode"] === "TargetOnly",
          TargetOnlySeedInt[leadingTarget, degreeBlocks[[syzygyID, ii]]],
          SeedInt[seedPre, degreeBlocks[[syzygyID, ii]], powerID]
        ],
        {ii, Length[degreeBlocks[[syzygyID]]]}];

      parallelID = Flatten[
        Table[{kk, ii, jj}, {kk, Length[degreeBlocks[[syzygyID]]]},
          {ii, Length[operatorBlocks[[syzygyID, kk]]]},
          {jj, Length[seedInt[[kk]]]}], 2];

      IBPRelation = ParallelTable[
          Operator2IBP[
            operatorBlocks[[syzygyID, parallelID[[nn, 1]], parallelID[[nn, 2]]]],
            Propagators4,
            seedInt[[parallelID[[nn, 1]], parallelID[[nn, 3]]]]],
          {nn, Length[parallelID]}] // DeleteDuplicates;

      Export[FileNameJoin[{outputDir,
          "sector" <> ToString[leadingSector[[2]]] <> "_syzygy" <>
            ToString[syzygyID] <> ".txt"}],
        IBPRelation // InputForm // ToString];
      Print["syzygy ", syzygyID, " done."],
      {syzygyID, Length[operatorBlocks]}];

    targetNoDelta = Complement[targetNoDelta, leadingTarget];
    flag++;
    Print["Finish ", flag, " sectors at ", DateString[]];
  ];

  IBPSet = Flatten[Get /@ FileNames["sector*_syzygy*.txt", outputDir]] // DeleteDuplicates;
  If[TrueQ[OptionValue["CleanFalseRelations"]],
    badID = Flatten[Position[IBPSet, False]];
    IBPSet[[Complement[Range[Length[IBPSet]], badID]]],
    IBPSet
  ]
];

(* ::Section:: *)
(*Differential-equation Helpers*)

Operator2DERat[IBPOperator_, operatorBas_, propagator_, intTarget_] := Module[
  {intProp, dlist, prolist, protectedIDs, dcoef, procoef, intVar, proPart,
   activePropIDs, propPart, result},
  intProp = List @@ intTarget;
  dlist = Select[operatorBas, Head[#] == d &];
  prolist = Select[operatorBas, Head[#] == pro &];
  protectedIDs = If[prolist === {}, {}, prolist[[All, 1]]];
  dcoef = Coefficient[IBPOperator, #, 1] & /@ dlist;
  procoef = Coefficient[IBPOperator, #, 1] & /@ prolist;
  intVar = dlist /. d -> Identity;
  proPart = If[prolist === {}, 0,
    Total[MapThread[-intProp[[#1]] procoef[[#2]] &,
      {prolist[[All, 1]], Range[Length[prolist[[All, 1]]]]}]]
  ];
  activePropIDs = Complement[Range[Length[propagator]], protectedIDs];
  propPart = Total[Flatten[Table[
        -intProp[[jj]] dcoef[[ii]] Dsp[propagator[[jj]], intVar[[ii]]]/
          propagator[[jj]],
        {jj, activePropIDs}, {ii, Length[intVar]}]]];
  result = proPart + propPart;
  result = Factor[Expand[result] /. {v[xx_] v[yy_] :> sp[xx, yy],
      v[xx_]^2 :> sp[xx, xx]}];
  If[result === 0, 0, result/Inner[Power, propagator, intProp, Times] // Factor]
];

Operator2DE[IBPOperator_, operatorBas_, propagator_, intTarget_] :=
  DropBadDeltaIntegrals[
    spInt2PowerIDInt[Operator2DERat[IBPOperator, operatorBas, propagator, intTarget],
      propagator] /. Kinematics];

DEexpr[intTarget_, IBPOperator_, propagator_] := Module[
  {intList, coeffList, intListv2, dlist = d /@ ExternalVars},
  intList = Select[Variables[intTarget], Head[#] == G &];
  coeffList = CoefficientRules[intTarget, intList][[All, 2]] // Factor;
  intListv2 = Inner[Power, intList, #, Times] & /@
    (CoefficientRules[intTarget, intList][[All, 1]]);
  ((Operator2DE[IBPOperator, dlist, propagator, #] & /@ intListv2) .
      coeffList) +
    (intListv2 . If[IBPOperator === DOperatorx, D[coeffList, x], D[coeffList, y]])
];

SimplifyMI[expr_] := Module[{miTemp, exprSimplify},
  miTemp = Select[Variables[expr], Head[#] == G &];
  exprSimplify = (CoefficientArrays[expr, miTemp][[2]] // Normal // Factor) . miTemp;
  Select[Variables[exprSimplify], Head[#] == G &]
];

SimplifyDE[expr_, MI_] := Module[{redunMI},
  redunMI = Complement[Select[Variables[expr], Head[#] == G &], MI];
  expr /. (# -> 0 & /@ redunMI)
];

FindOppositeCoefficientPairs[expr_] := Module[
  {ints, coeffs, grouped},
  ints = Select[Variables[expr], Head[#] == G &];
  coeffs = Coefficient[expr, #] & /@ ints;
  grouped = GatherBy[Transpose[{ints, coeffs}], Factor[Abs[#[[2]]]] &];
  Select[grouped, Length[#] >= 2 && Length[Union[Factor /@ #[[All, 2]]]] > 1 &]
];

BuildDEIteratively[targetBasis_, reductionRules_, finiteReplacementRules_ : {},
   maxRounds_Integer : 8] := Module[
  {basis = targetBasis, newBasis, round = 0, dx, dy},
  While[round < maxRounds,
    round++;
    dx = (DEexpr[#, DOperatorx, Propagators4] /. reductionRules //.
          finiteReplacementRules) & /@ basis;
    dy = (DEexpr[#, DOperatory, Propagators4] /. reductionRules //.
          finiteReplacementRules) & /@ basis;
    newBasis = Union[basis, Flatten[SimplifyMI /@ Join[dx, dy]]];
    Print["DE round ", round, ": basis size ", Length[basis], " -> ",
      Length[newBasis]];
    If[Length[newBasis] == Length[basis], Break[]];
    basis = newBasis;
  ];
  basis
];

Print["Loaded four-loop ladder IBP tools."];
Print["Propagators = ", Propagators // InputForm];
Print["Delta propagators = ", DeltaPropagators // InputForm];
Print["TopSectorPowerID = ", TopSectorPowerID // InputForm];
