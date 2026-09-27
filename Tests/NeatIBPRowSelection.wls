package=DirectoryName[DirectoryName[$InputFileName]];
neat=Environment["NEATIBP_ROOT"];spasm=Environment["SPASM_LIBRARY"];
If[!StringQ[neat]||!DirectoryQ[neat],Print["Optional test requires NEATIBP_ROOT."];Quit[77]];
SparseRREF`SpaSMLibrary=If[StringQ[spasm],spasm,"/usr/local/lib/libspasm.so"];
Get[FileNameJoin[{neat,"SparseRREF","SparseRREF.m"}]];
Get[FileNameJoin[{package,"Adapters","NeatIBPRowSelection.wl"}]];
p=42013;
(* Columns 4 and 5 are symbolic source columns. Their existing constraint is
   necessary for the normal form of column 1; no lower-loop equation is made. *)
m=SparseArray[{{1,-11,0,-1,0},{0,1,-17,0,0},{0,0,0,1,-28},{2,-22,0,-2,0},{0,1,-17,1,-28}}];
r=ConformalIBPNeatSelection`SelectSparseTargetRows[m,{1},p];
If[FailureQ[r],Print[r];Quit[2]];
(* Independent finite-field reference only, never symbolic RowReduce. *)
reference=RowReduce[Normal[m],Modulus->p];selected=RowReduce[Normal[m[[r["Rows"]]]],Modulus->p];
tests=<|"TargetNormalForm"->(First[reference]===First[selected]),"Rank"->(r["Rank"]===3),
 "BoundaryConstraintRetained"->(First[selected][[5]]=!=0),
 "FreeTargets"->(ConformalIBPNeatSelection`SelectSparseTargetRows[m,{3,5},p]["Rows"]==={}),
 "ZeroMatrix"->(ConformalIBPNeatSelection`SelectSparseTargetRows[SparseArray[{},{3,5}],{1},p]["Rows"]==={}),
 "PrimeLimit"->FailureQ[ConformalIBPNeatSelection`SelectSparseTargetRows[m,{1},1000003]],
 "NonzeroImplicitValue"->FailureQ[ConformalIBPNeatSelection`SelectSparseTargetRows[SparseArray[{},{3,5},1],{1},p]],
 "KnownIndependentInput"->(ConformalIBPNeatSelection`SelectSparseTargetRows[m[[{1,2,3}]],{1},p,"InputRowsIndependent"->True]["Rows"]==={1,2,3}),
 "FalseIndependenceRejected"->FailureQ[ConformalIBPNeatSelection`SelectSparseTargetRows[m,{1},p,"InputRowsIndependent"->True]]|>;
Print[tests];Quit[If[And@@Values[tests],0,3]];
