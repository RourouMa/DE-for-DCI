root=DirectoryName[DirectoryName[$InputFileName]];Get[FileNameJoin[{root,"Kernel","ConformalIBP.wl"}]];
bundle=FileNameJoin[{DirectoryName[root],"three-loop-DE-results-20260923"}];name=Last[$CommandLine];
cfg=Get[FileNameJoin[{bundle,name,"FamilyConfiguration.wl"}]];
f=CreateFamily[KeyTake[cfg["LoopFamilies"][3],{"Name","Dimension","External","Loops","Variables","Kinematics","ExternalDerivatives","ExternalPermutations","Propagators","TopSector","SuperSectors","Completion","IntegralOrdering","MaxLoopPower"}]];
sector=Flatten[Position[f["TopSector"],1]];rep=ParametricRepresentation[f,sector];
If[FailureQ[rep],Print[rep];Quit[1]];
out=FileNameJoin[{root,"runs","critical-count-20260923",name}];If[!DirectoryQ[out],CreateDirectory[out,CreateIntermediateDirectories->True]];
Put[rep,FileNameJoin[{out,"ParametricRepresentation.wl"}]];
Print[<|"Name"->name,"Sector"->sector,"Parameters"->Length[rep["Parameters"]],"Terms"->Length[MonomialList[rep["Polynomial"],rep["Parameters"]]]|>];
(* A modular generic-point probe is recorded as such, never as a certified bound. *)
point={x->7338376896737913617,y->7718278679044643367};
r=CriticalPointCount[rep["Polynomial"]/.point,rep["Parameters"],"Modulus"->1000003,"TimeLimit"->120];
Put[<|"ReferenceRepresentation"->rep,"Point"->point,"Result"->r,"IsMasterIntegralUpperBound"->False|>,FileNameJoin[{out,"TopSectorProbe.wl"}]];
Print[If[FailureQ[r],r,KeyTake[r,{"Status","Count","Seconds","IsMasterIntegralUpperBound"}]]];Quit[If[FailureQ[r],2,0]];
