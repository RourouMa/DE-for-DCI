root=DirectoryName[DirectoryName[$InputFileName]];Get[FileNameJoin[{root,"Kernel","ConformalIBP.wl"}]];
assert[t_,name_]:=If[TrueQ[t],Print["PASS ",name],Print["FAIL ",name];Quit[1]];
g=G[1];h=G[2];b=BoundaryIntegral[1,{1,1}];
images={g,h,0,g+h,g+b,((x^2-1)/(x-1)-x)g,g+(1/(x-1)-(x+1)/(x^2-1))h,((x^2-1)/(x-1)-x-1)g+h};
assert[(ConformalIBP`Private`selfReducedIntegralQ[g,#]& /@ images)===(TrueQ[Together[#-g]===0]& /@ images),"identity decisions agree with exact rational test"];
assert[!ConformalIBP`Private`selfReducedIntegralQ[g,Sum[G[k]/(x+k),{k,2,1000}]],"distinct integral columns cannot equal the target"];
assert[RecommendedWorkerCount[32]===26 && RecommendedWorkerCount[1]===1 && RecommendedWorkerCount[8]===6,"recommended worker count rounds four fifths"];
assert[RecommendedWorkerCount[]===Max[1,Round[4 $ProcessorCount/5]],"hardware recommendation"];
assert[$MessageList==={},"no unexpected Wolfram messages"];Quit[0];
