r="/home/april/Documents/ChatGPT/DE for DCI";d=DirectoryName[$InputFileName];Get[r<>"/DE-for-DCI-publish/Kernel/ConformalIBP.wl"];
Clear[ConformalIBP`Private`poolRows,ConformalIBP`Private`poolMetadata,Global`poolRows];
Get[r<>"/four-loop-relative-cover-20260927/epoch0/full-pool-cache/CanonicalPool.mx"];rows=ConformalIBP`Private`poolRows;f=ConformalIBP`Private`poolMetadata["Family"];
Print["HighPoolRows ",Length[rows]]; poolKeys=AssociationThread[rows,Range[Length[rows]]];Clear[rows,ConformalIBP`Private`poolRows,ConformalIBP`Private`poolColumns];
Get[r<>"/four-loop-full-closure-20260927/epoch3/Benchmark.mx"];br=ConformalIBP`Private`benchmark["Rows"];Print["SelectedRows ",Length[br]];selKeys=AssociationThread[br,Range[Length[br]]];Clear[br,ConformalIBP`Private`benchmark];
records={};
Do[
 Clear[wholeGeneration,coupledGeneration];Get[r<>file];
 If[mode==="Coupled",g=coupledGeneration;raw=g["Generation"]["Equations"],g=wholeGeneration;raw=g["Relations"]];
 Print["GenerationKeys ",mode," ",Keys[g]];
 a=DeleteCases[ConformalIBP`Private`canonExpr[f,#]& /@ raw,0];
 poolIDs=Map[Lookup[poolKeys,Key[#],0]&,a];selIDs=Map[Lookup[selKeys,Key[#],0]&,a];
 rec=<|"Mode"->mode,"File"->file,"CandidateRows"->Length[a],"CurrentHighPoolMatches"->Count[poolIDs,_?Positive],"CurrentSelectedNativeMatches"->Count[selIDs,_?Positive],"CurrentHighPoolIndices"->DeleteCases[poolIDs,0],"CurrentSelectedIndices"->DeleteCases[selIDs,0]|>;
 Print[rec];AppendTo[records,rec];
 If[mode==="Coupled",Put[Select[g["Generation"]["Certificates"],MemberQ[a[[Flatten[Position[poolIDs,_?Positive,Heads->False]]]],ConformalIBP`Private`canonExpr[f,#["Equation"]]]&],d<>"/CoupledRowsInCurrentPool.wl"]],
 {item,{{"Coupled","/neatibp-evaluation-20260926/epoch5/highest-block/growth-directions/coupled-chain-full/Generation.mx"},{"WholeFinite","/neatibp-evaluation-20260926/epoch5-prefix-demand/whole-finite-seeding/Generation.mx"},{"WholeConstant","/neatibp-evaluation-20260926/epoch5-prefix-demand/whole-constant-seeding/Generation.mx"}}},
 {mode,{item[[1]]}},{file,{item[[2]]}}];
Export[d<>"/JointPoolMembershipAudit.json",<|"Records"->records,"Comparison"->"Exact symbolic native canonical rows; original pool unchanged; selected rows source-free matches literal."|>,"RawJSON"];Quit[];
