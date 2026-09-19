root=DirectoryName[DirectoryName[$InputFileName]];
Get[FileNameJoin[{root,"Kernel","ConformalIBP.wl"}]];
Get[FileNameJoin[{root,"Examples","kinematics.wl"}]];
family=LadderFamily[1,kinematics,{x,y}];
result=RunReduction[family,{G[-2,2,4,0,1]},"Solver"->"Exact",
 "OutputDirectory"->FileNameJoin[{root,"runs","reduction"}]];
Print[KeyTake[result,{"Status","ReducedInputs"}]];
Quit[If[FailureQ[result] || FailureQ[Lookup[result,"Status",None]],1,0]];
