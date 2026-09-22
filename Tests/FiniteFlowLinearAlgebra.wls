root=DirectoryName[DirectoryName[$InputFileName]];Get[FileNameJoin[{root,"Kernel","ConformalIBP.wl"}]];
assert[t_,name_]:=If[TrueQ[t],Print["PASS ",name],Print["FAIL ",name];Quit[1]];
assert[TrueQ[InitializeFiniteFlow[Environment["FINITEFLOW_ROOT"],FileNameJoin[{Environment["FINITEFLOW_ROOT"],"mathlink"}]]],"FiniteFlow initialized"];
m={{u,1,0},{2 u,2,0},{0,0,0}};r=ConformalIBP`Private`rr[m];
assert[r==={{1,1/u,0}},"symbolic row space with dependent and zero rows"];
a={{u,1},{v,2}};b=ConformalIBP`Private`linearInverse[a];
assert[And@@(ConformalIBP`Private`zero /@ Flatten[a.b-IdentityMatrix[2]])&&And@@(ConformalIBP`Private`zero /@ Flatten[b.a-IdentityMatrix[2]]),"both inverse identities exact"];
assert[ConformalIBP`Private`rr[{{0 u,0},{0,0}}]==={},"zero row space"];
assert[$MessageList==={},"no unexpected messages"];Quit[0];
