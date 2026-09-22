root=DirectoryName[DirectoryName[$InputFileName]];Get[FileNameJoin[{root,"Kernel","ConformalIBP.wl"}]];
Get[FileNameJoin[{root,"Examples","kinematics.wl"}]];
assert[t_,name_]:=If[TrueQ[t],Print["PASS ",name],Print["FAIL ",name];Quit[1]];
f=LadderFamily[2,kinematics,{x,y}];g=G@@Join[f["TopSector"],{1,1}];a=G[2,0,0,0,0,2,0,0,2,1,1];b=G[2,0,0,2,1,1,0,2,0,1,1];
assert[f["IntegralOrdering"]==="TierReference","O6 default"];
assert[ConformalIBP`Private`fourTier[f,g]===1&&ConformalIBP`Private`fourTier[f,a]===0&&ConformalIBP`Private`fourTier[f,b]===3,"finite and factorized tier priorities"];
Do[q=CreateFamily[Join[KeyDrop[f,{"Hash"}],<|"IntegralOrdering"->s|>]];assert[AssociationQ[q]&&ListQ[ConformalIBP`Private`simpleKey[q,b]],s],{s,{"Legacy","LadderFirst","Reference","TierBlocks","TierLadder","TierReference"}}];
assert[ConformalIBP`Private`simpleKey[f,b]===Prepend[ConformalIBP`Private`ordering01InnerKey[f,b],3],"O6 uses ordering01 inside tier"];
assert[$MessageList==={},"no unexpected messages"];Quit[0];
