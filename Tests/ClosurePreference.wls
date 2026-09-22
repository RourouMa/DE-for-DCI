Get[FileNameJoin[{DirectoryName[DirectoryName[$InputFileName]],"Kernel","ConformalIBP.wl"}]];
assert[test_,name_]:=If[TrueQ[test],Print["PASS ",name],Print["FAIL ",name];Quit[1]];
kin={SP[X1,X1]->2 x,SP[X3,X3]->2 x,SP[X2,X2]->2 y,SP[X4,X4]->2 y,
 SP[X1,X3]->1+x^2,SP[X2,X4]->1+y^2,SP[X1,X2]->0,SP[X1,X4]->0,SP[X2,X3]->0,SP[X3,X4]->0};
base=LadderFamily[1,kin,{x,y}];
f=CreateFamily[Join[KeyDrop[base,{"Hash"}],<|"TopSector"->{0,1,1,1},"SuperSectors"->{{1,2,3,4}},"ExternalPermutations"->{{1,2,3,4}}|>]];
assert[AssociationQ[f] && f["IntegralOrdering"]==="TierReference","four-tier reference ordering is default"];
legacy=CreateFamily[Join[KeyDrop[f,{"Hash"}],<|"IntegralOrdering"->"LadderFirst"|>]];
prepared=ConformalIBP`Private`makeState[legacy,{},"DE",Join[Association[Options[RunDE]],<|"BasisPreference"->"FamilyAfterClosure"|>]];
assert[prepared["Family"]["IntegralOrdering"]==="ClosureFirst" && ConformalIBP`Private`familyHash[prepared["Family"]]===prepared["FamilyHash"],"old LadderFirst specification cannot override closure priority"];
g=G[1,1,1,1,1];h=G[0,2,1,1,1];q=G[1,2,1,0,1];b=BoundaryIntegral[1,{1,1,1,1,1}];
assert[And@@(FiniteIntegralQ[f,#]& /@ {g,h,q}),"test candidates pass actual finite validator"];
state=<|"Family"->f,"Basis"->{g,q},"OriginalInputs"->{g},"Closed"->True,"FlatnessVerified"->True,
 "Matrices"-><|x->{{0,0},{0,0}},y->{{0,0},{0,0}}|>,"BoundaryRows"->{0,0,0,0},
 "LastReduction"-><|"Rules"->{g->g,q->q,h->x g}|>,"InputReconstructionMatrix"->{{1,0}}|>;
r=ConformalIBP`Private`preferFamilyAfterClosure[state];
assert[r["FamilyPreferenceAudit"]["Applied"] && r["FamilyPreferenceAudit"]["OriginalFamilyCountAfter"]===1,"prefer in-family representative only after closure"];
assert[MemberQ[r["Basis"],h] && Length[r["Basis"]]===2 && MemberQ[r["Basis"],q],"necessary outside-family direction retained"];
assert[And@@(ConformalIBP`Private`zero /@ Flatten[r["FamilyPreferenceTransform"].r["FamilyPreferenceInverse"]-IdentityMatrix[2]]),"replacement is invertible"];
t=r["FamilyPreferenceTransform"];inv=r["FamilyPreferenceInverse"];
assert[And@@(ConformalIBP`Private`zero /@ Flatten[r["Matrices"][x]-D[t,x].inv]),"kinematic change-of-basis derivative included"];
assert[And@@(ConformalIBP`Private`zero /@ Flatten[r["InputReconstructionMatrix"].t-state["InputReconstructionMatrix"]]),"original input reconstruction updated"];
unclosed=ConformalIBP`Private`preferFamilyAfterClosure[Join[state,<|"Closed"->False,"ClosedModuloBoundary"->True|>]];
assert[!unclosed["FamilyPreferenceAudit"]["Applied"] && unclosed["Basis"]===state["Basis"],"quotient closure cannot authorize family optimization"];
unflat=ConformalIBP`Private`preferFamilyAfterClosure[Join[state,<|"FlatnessVerified"->False|>]];
assert[!unflat["FamilyPreferenceAudit"]["Applied"],"unverified flatness cannot authorize family optimization"];
boundary=ConformalIBP`Private`preferFamilyAfterClosure[Join[state,<|"LastReduction"-><|"Rules"->{g->g,q->q,h->x g+b}|>|>]];
assert[!MemberQ[boundary["Basis"],h],"candidate with unmatched boundary source rejected"];
outside=ConformalIBP`Private`preferFamilyAfterClosure[Join[state,<|"LastReduction"-><|"Rules"->{g->g,q->q,h->h}|>|>]];
assert[!MemberQ[outside["Basis"],h],"finite candidate outside closed span rejected"];
assert[FailureQ[RunDE[base,g,"BasisPreference"->"invalid","ProgressFunction"->None]],"invalid preference rejected"];
assert[$MessageList==={},"no unexpected Wolfram messages"];Quit[0];
