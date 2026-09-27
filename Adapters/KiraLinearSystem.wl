(* Kira's user-defined equations need no momentum-space integral family.
   Keep the caller's exact integral/source column order using reverse weights. *)
BeginPackage["ConformalIBPKira`"];
ExportKiraLinearSystem::usage="ExportKiraLinearSystem[newDirectory,equations,orderedColumns,targetAtoms] exports existing DCI equations to Kira's user-defined-system interface without generating IBPs.";
ReadKiraLinearSystem::usage="ReadKiraLinearSystem[directory] maps Kira results back to the original integral atoms. Results still require an independent full-system check.";
Begin["`Private`"];
ExportKiraLinearSystem[directory_String,rows_List,columns_List,targets_List]:=Module[
 {maps,atoms,weights,present,requested,stream,metadata,input,job},
 If[!MemberQ[$Packages,"ConformalIBP`"],Return[Failure["ConformalIBPNotLoaded",<||>]]];
 If[!DuplicateFreeQ[columns]||Complement[targets,columns]=!={}||
   !AllTrue[columns,MatchQ[#,_ConformalIBP`G|_ConformalIBP`BoundaryIntegral]&],Return[Failure["IntegralColumns",<||>]]];
 maps=ConformalIBP`Private`linearMapNoExpand /@ rows;
 If[AnyTrue[maps,FailureQ],Return[Failure["LinearInput",<||>]]];
 atoms=Union[Flatten[Keys /@ maps]];
 If[Complement[atoms,columns]=!={},Return[Failure["MissingColumns",<||>]]];
 If[DirectoryQ[directory]&&FileNames["*",directory]=!={},Return[Failure["NewDirectoryRequired",<||>]]];
 If[!DirectoryQ[directory],CreateDirectory[directory,CreateIntermediateDirectories->True]];
 CreateDirectory[FileNameJoin[{directory,"userSystem"}]];
 weights=AssociationThread[columns,Reverse[Range[Length[columns]]]];
 requested=Select[DeleteDuplicates[targets],MemberQ[atoms,#]&];
 input=FileNameJoin[{directory,"userSystem","userdefinedsystem.kira"}];stream=OpenWrite[input];
 Scan[(KeyValueMap[WriteString[stream,ToString[weights[#1]],"*(",
   StringReplace[ToString[InputForm[Together[#2]]],WhitespaceCharacter->""],")\n"]&,#];WriteString[stream,"\n"])&,maps];Close[stream];
 Export[FileNameJoin[{directory,"list"}],StringRiffle[ToString /@ Lookup[weights,requested],"\n"]<>"\n","Text"];
 job="jobs:\n  - reduce_user_defined_system:\n      input_system: {files: [\"userSystem\"], otf: true, config: false}\n      select_integrals:\n        select_mandatory_list:\n          - [list]\n      run_initiate: true\n      run_triangular: true\n      run_back_substitution: true\n  - kira2math:\n      target:\n        - [list]\n";
 Export[FileNameJoin[{directory,"jobs.yaml"}],job,"Text"];
 metadata=<|"Columns"->columns,"Targets"->targets,"RequestedWeights"->Lookup[weights,requested],
   "InputHash"->Hash[{rows,columns,targets},"SHA256"],"InputFileSHA256"->FileHash[input,"SHA256"],
   "ListSHA256"->FileHash[FileNameJoin[{directory,"list"}],"SHA256"],"RunRequired"->(requested=!={}),
   "BoundaryColumns"->Count[columns,_ConformalIBP`BoundaryIntegral],"SourcesSetToZero"->False|>;
 Put[metadata,FileNameJoin[{directory,"ColumnMap.wl"}]];metadata
];
ReadKiraLinearSystem[directory_String]:=Module[{meta,file,raw,indices,rules,columns},
 meta=Get[FileNameJoin[{directory,"ColumnMap.wl"}]];
 If[!AssociationQ[meta],Return[Failure["ColumnMap",<||>]]];
 If[meta["InputFileSHA256"]=!=FileHash[FileNameJoin[{directory,"userSystem","userdefinedsystem.kira"}],"SHA256"]||
   meta["ListSHA256"]=!=FileHash[FileNameJoin[{directory,"list"}],"SHA256"],Return[Failure["InputChanged",<||>]]];
 If[!TrueQ[meta["RunRequired"]],Return[Thread[meta["Targets"]->meta["Targets"]]]];
 file=FileNameJoin[{directory,"results","Tuserweight","kira_list.m"}];
 If[!FileExistsQ[file],Return[Failure["KiraResultsMissing",<||>]]];raw=Get[file];columns=meta["Columns"];
 If[!MatchQ[raw,{___Rule}],Return[Failure["KiraRules",<||>]]];
 indices=Cases[raw,h_[i_]/;Head[h]===Symbol&&SymbolName[h]==="Tuserweight":>i,Infinity];
 If[!VectorQ[indices,IntegerQ[#]&&1<=#<=Length[columns]&],Return[Failure["KiraWeights",<||>]]];
 rules=raw/.h_[i_Integer]/;Head[h]===Symbol&&SymbolName[h]==="Tuserweight":>columns[[-i]];
 If[!AllTrue[rules,MemberQ[meta["Targets"],First[#]]&]||!DuplicateFreeQ[First /@ rules],Return[Failure["UnexpectedKiraTargets",<||>]]];
 Thread[meta["Targets"]->(meta["Targets"]/.Dispatch[rules])]
];
End[];EndPackage[];
