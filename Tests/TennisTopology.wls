root=DirectoryName[DirectoryName[$InputFileName]];Get[FileNameJoin[{root,"Kernel","ConformalIBP.wl"}]];
Get[FileNameJoin[{root,"Examples","kinematics.wl"}]];
spec=Get[FileNameJoin[{root,"Examples","tennis-court-family.wl"}]];f=spec["Family"];
original=Pick[f["Propagators"],f["TopSector"],1];
specs={<|"Pair"->{Y1,Y2},"Orientation"->"Horizontal","Contract"->(Y3->X4),"ExpectedIDs"->{1,2,4,6,7,8,13},"Spectator"->Y3|>,
<|"Pair"->{Y1,Y3},"Orientation"->"Horizontal","Contract"->(Y2->X2),"ExpectedIDs"->{1,2,4,10,11,12,15},"Spectator"->Y2|>,
<|"Pair"->{Y2,Y3},"Orientation"->"Vertical","Contract"->(Y1->X1),"ExpectedIDs"->{5,6,7,9,11,12,14},"Spectator"->Y1|>};
topologyRecords=Table[With[{remaining=spec["Pair"],rule=spec["Contract"]},
 minor=Union[Select[original/.rule,Function[prop,AnyTrue[remaining,!FreeQ[prop,#]&]]]];
 ids=Sort[First[FirstPosition[f["Propagators"],#]]& /@ minor];
 sector=Union[ids,Flatten[Position[f["Supports"],{First[FirstPosition[f["Loops"],spec["Spectator"]]]},{1},Heads->False]]];
 Join[spec,<|"ContractedEdgePresent"->MemberQ[original,SP[First[rule],Last[rule]]],"DerivedIDs"->ids,"DerivedFactorizedSector"->sector,"Passed"->(ids===spec["ExpectedIDs"] && MemberQ[f["SuperSectors"],sector])|>]],{spec,specs}];
passed=And@@Join[Lookup[topologyRecords,"Passed"],Lookup[topologyRecords,"ContractedEdgePresent"]]&&FiniteIntegralQ[f,top]&&f["Completion"]==="FamilyOnly";
Print[<|"TopologyContractionsPassed"->passed,"Records"->topologyRecords|>];Quit[If[passed&&$MessageList==={},0,1]];
