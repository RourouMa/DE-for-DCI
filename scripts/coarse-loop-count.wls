root=DirectoryName[DirectoryName[$InputFileName]];Get[FileNameJoin[{root,"Kernel","ConformalIBP.wl"}]];
{name,loopText}=Take[$CommandLine,-2];loops=ToExpression[loopText];bundle=FileNameJoin[{DirectoryName[root],"three-loop-DE-results-20260923"}];
cfg=Get[FileNameJoin[{bundle,name,"FamilyConfiguration.wl"}]];
f=CreateFamily[KeyTake[cfg["LoopFamilies"][loops],{"Name","Dimension","External","Loops","Variables","Kinematics","ExternalDerivatives","ExternalPermutations","Propagators","TopSector","SuperSectors","Completion","IntegralOrdering","MaxLoopPower"}]];
top=If[loops===3,First[cfg["OriginalInput"]],G@@Join[f["TopSector"],ConstantArray[1,loops]]];
out=FileNameJoin[{root,"runs","coarse-loop-count-20260923",name<>"-"<>loopText}];If[!DirectoryQ[out],CreateDirectory[out,CreateIntermediateDirectories->True]];
result=MasterIntegralCount[f,{top},"TimeLimit"->5,"TotalTimeLimit"->45,"ProgressFunction"->None];
Put[result,FileNameJoin[{out,"Count.wl"}]];
summary=If[FailureQ[result],<|"Failure"->ToString[result,InputForm]|>,Join[KeyTake[result,{"Status","Count","CertifiedUpperBound","LoopCount","OriginalSectorCount","RepresentativeSectorCount","UnquotientedReferenceCount","SectorOrbitReferenceCount","Seconds"}],
 <|"CompletedSectorAttempts"->Length[result["SectorResults"]],"UncomputedSectors"->Length[result["UncomputedSectors"]],"FailedSectors"->Count[result["SectorResults"],a_/;FailureQ[a["CriticalCount"]]],"Scheme"->"Exact characteristic-zero proper-sector reference with symmetry"|>]];
Export[FileNameJoin[{out,"Summary.json"}],summary/._Missing->Null,"RawJSON"];Print[summary];Quit[0];
