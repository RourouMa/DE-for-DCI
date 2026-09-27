$IterationLimit=Infinity;out=DirectoryName[$InputFileName];root=DirectoryName[DirectoryName[out]];
f=FileNameJoin[{root,"four-loop-dlog-20260927","structure","Full88DLogCandidate.wl"}];a=Get[f];letters=a["Letters"];cm=a["ResidueMatrices"];
rat[r_]:={ToString[Numerator[r],InputForm],ToString[Denominator[r],InputForm]};
cr[p_]:=({First[#],rat[Last[#]]}& /@ CoefficientRules[Expand[p],{x,y}]);
sp[m_]:=Module[{pos=Position[m,_?(#=!=0&),{2},Heads->False]},({#[[1]]-1,#[[2]]-1,rat[Extract[m,#]]}& /@pos)];
top=a["NewToNative"][[1]];topdata=MapIndexed[If[#1===0,Nothing,With[{z=Together[#1]},<|"Index"->(First[#2]-1),"Numerator"->cr[Numerator[z]],"Denominator"->cr[Denominator[z]]|>]]&,top];
Export[FileNameJoin[{out,"DLogNumericalData.json"}],<|"CandidateFile"->f,"CandidateSHA256"->IntegerString[FileHash[f,"SHA256"],16,64],"Dimension"->88,"Letters"->(ToString[#,InputForm]& /@letters),"LetterPolynomials"->(cr /@letters),"ResidueMatrices"->(sp /@cm),"TopCoefficients"->topdata|>,"RawJSON"];
Print["letters ",Length[letters]," residue terms ",Length /@ (sp /@cm)," top terms ",Length[topdata]];Quit[0];
