root=DirectoryName[DirectoryName[$InputFileName]];
Get[FileNameJoin[{root,"Kernel","ConformalIBP.wl"}]];
Get[FileNameJoin[{root,"Examples","kinematics.wl"}]];
family=LadderFamily[1,kinematics,{x,y}];
result=RunDE[family,G[1,1,1,1,1],"Solver"->"Exact",
 "OutputDirectory"->FileNameJoin[{root,"runs","one-loop"}]];
Print[KeyTake[result,{"Status","Basis","Matrices","FlatnessVerified"}]];
Quit[If[TrueQ[result["Closed"]],0,1]];
