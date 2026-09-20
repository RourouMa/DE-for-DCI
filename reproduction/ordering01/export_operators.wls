(* Maintainer conversion from the original machine-specific MX to portable text. *)
hHome=DirectoryName[$InputFileName];hFile=Environment["DCI_OPERATOR_MX"];
If[!StringQ[hFile] || !FileExistsQ[hFile],Print["Set DCI_OPERATOR_MX"];Quit[1]];
SingularInterfacePath="";Get[FileNameJoin[{hHome,"legacy","IBP4loop.wl"}]];
hBlocks=Import[hFile];hOps=hBlocks[[1,1]];hDegrees=hBlocks[[1,2]];
hOK=And@@Flatten[Table[HomogeneousQ[#/.pro[_]->0]===hDegrees[[i]]& /@ hOps[[i]],{i,Length[hOps]}]];
If[!hOK,Print["Operator degree mismatch"];Quit[1]];
Put[hBlocks,FileNameJoin[{hHome,"Operators.wl"}]];
Put[<|"Operators"->Total[Length /@ hOps],"Degrees"->hDegrees,
 "DegreeCounts"->Thread[hDegrees->(Length /@ hOps)],"AllHomogeneous"->hOK,
 "PortableRoundTrip"->(Get[FileNameJoin[{hHome,"Operators.wl"}]]===hBlocks),
 "GeneratorFingerprint"->(Get[FileNameJoin[{hHome,"legacy","IBP4GeneratorVersion.wl"}]];IBP4GeneratorFingerprint[])|>,
 FileNameJoin[{hHome,"OperatorAudit.wl"}]];
Print[Get[FileNameJoin[{hHome,"OperatorAudit.wl"}]]//InputForm];Quit[];
