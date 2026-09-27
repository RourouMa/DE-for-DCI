root=DirectoryName[DirectoryName[$InputFileName]];Get[FileNameJoin[{root,"Kernel","ConformalIBP.wl"}]];
files=FileNames["Count.wl",FileNameJoin[{root,"runs","coarse-loop-count-20260923"}],Infinity];
Do[r=Get[file];bad=Select[r["SectorResults"],FailureQ[#["CriticalCount"]]&];
 summary=Join[KeyTake[r,{"Status","Count","CertifiedUpperBound","LoopCount","OriginalSectorCount","RepresentativeSectorCount","UnquotientedReferenceCount","SectorOrbitReferenceCount","Seconds"}],
 <|"CompletedSectorAttempts"->Length[r["SectorResults"]],"UncomputedSectors"->Length[r["UncomputedSectors"]],"FailedSectors"->Length[bad],"FailureTypes"->Counts[(#["CriticalCount"][[1]]& /@ bad)]|>];
 Export[FileNameJoin[{DirectoryName[file],"Summary.json"}],summary/._Missing->Null,"RawJSON"];Print[<|"File"->file,"Summary"->summary|>],{file,files}];Quit[0];
