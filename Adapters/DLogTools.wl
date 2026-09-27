(* Optional exact tools extracted from the verified four-loop ladder calculation.
   This decomposes/verifies a supplied connection; it is not an automatic gauge search. *)
BeginPackage["ConformalIBPDLog`"];
FindConstantDLog::usage="FindConstantDLog[Ax,Ay,letters,{x,y}] fits exact rational constant residues and always checks the full symbolic reconstruction.";
VerifyGauge::usage="VerifyGauge[Ax,Ay,T,Tinv,Bx,By,letters,{x,y}] verifies both inverses, both gauge identities, curvature and constant residues for J=T.I.";
DLogFactorList::usage="DLogFactorList[matrices,vars] returns denominator factors as candidate letters, not a certified minimal alphabet.";
RationalPrimitivePart::usage="RationalPrimitivePart[f,z] extracts the rational primitive in univariate Hermite reduction. It does not solve a coupled gauge equation.";
Begin["`Private`"];
(* Constant-residue dlog decomposition. All linear algebra below is on
   exact constant rational sample matrices, never on kinematic matrices. *)
Clear[DCIDLogZeroQ,DLogFactorList,FindConstantDLog];
DCIDLogZeroQ[e_]:=SameQ[Cancel[Together[e]],0];
DLogFactorList[matrices_List,vars_List]:=Module[{fs},
 fs=DeleteDuplicates[First /@ Flatten[(Rest[FactorList[Denominator[Together[#]]]]& /@ DeleteCases[Flatten[matrices],0]),1]];
 DeleteDuplicates[Sort[(If[Last[Last[CoefficientRules[#,vars]]]<0,-#,#]& /@ fs)]]
];
Options[FindConstantDLog]={"SamplePoints"->{{2,3},{3,5},{5,7},{7,11},{11,13},{13,17},{17,19},{19,23},{23,29},{29,31},{31,37},{37,41},{41,43},{43,47},{47,53},{53,59},{59,61},{61,67},{67,71},{71,73}}};
FindConstantDLog[ax_List,ay_List,letters_List,vars:{vx_,vy_},OptionsPattern[]]:=Module[
 {fx,fy,points,kernels,rows,modrows,rref,pivots,selected,targets,coef,residues,rx,ry,n=Length[ax],p=1000000007,samples,rank},
 If[n==0 || Dimensions[ax]=!={n,n} || Dimensions[ay]=!={n,n},Return[Failure["Shape",<||>]]];
 If[letters==={},Return[Failure["EmptyAlphabet",<||>]]];
 fx=Cancel[D[#,vx]/#]& /@ letters;fy=Cancel[D[#,vy]/#]& /@ letters;
 points=Select[OptionValue["SamplePoints"],Function[pt,
  Length[pt]==2 && AllTrue[pt,MatchQ[#, _Integer|_Rational]&] &&
  With[{vals=Quiet[Join[fx,fy,Flatten[ax],Flatten[ay]]/.Thread[vars->pt]]},
   AllTrue[vals,MatchQ[#, _Integer|_Rational] && Mod[Denominator[#],p]!=0&]]]];
 If[points==={},Return[Failure["NoValidSamples",<||>]]];
 kernels=Flatten[Table[{fx,fy}/.Thread[vars->pt],{pt,points}],1];
 modrows=Map[Mod[Numerator[#]*PowerMod[Denominator[#],-1,p],p]&,kernels,{2}];
 rref=RowReduce[Transpose[modrows],Modulus->p];
 pivots=DeleteCases[(If[AllTrue[#,SameQ[#,0]&],Nothing,First[FirstPosition[#,a_/;a!=0]]])& /@ rref,Nothing];rank=Length[pivots];
 If[rank=!=Length[letters],Return[Failure["DependentLetters",<|"Rank"->rank,"Letters"->Length[letters]|>]]];
 selected=kernels[[pivots]];
 targets=Table[samples=points[[Ceiling[k/2]]];Flatten[If[OddQ[k],ax,ay]/.Thread[vars->samples]],{k,pivots}];
 coef=LinearSolve[selected,targets];
 residues=ArrayReshape[#,{n,n}]& /@ coef;
 rx=Map[Cancel[Together[#]]&,ax-Sum[residues[[k]] fx[[k]],{k,Length[letters]}],{2}];
 ry=Map[Cancel[Together[#]]&,ay-Sum[residues[[k]] fy[[k]],{k,Length[letters]}],{2}];
 <|"Letters"->letters,"ResidueMatrices"->residues,"XResidual"->rx,"YResidual"->ry,
 "Passed"->AllTrue[Flatten[{rx,ry}],SameQ[#,0]&],"ConstantResidues"->FreeQ[residues,vx|vy],
 "IndependentSamplingRows"->pivots,"SamplingPoints"->points,"Method"->"Exact rational sample solve followed by full symbolic reconstruction"|>
];
Clear[VerifyGauge];
VerifyGauge[ax_List,ay_List,t_List,ti_List,bx_List,by_List,letters_List,vars:{vx_,vy_}]:=Module[
 {n=Length[ax],simp,invLeft,invRight,gx,gy,curv,dl,res},
 If[n==0 || !AllTrue[{ax,ay,t,ti,bx,by},Dimensions[#]=={n,n}&],Return[Failure["Shape",<||>]]];
 simp[m_]:=Map[Cancel[Together[#]]&,m,{2}];
 invLeft=simp[t.ti-IdentityMatrix[n]];
 invRight=simp[ti.t-IdentityMatrix[n]];
 gx=simp[bx.t-D[t,vx]-t.ax];
 gy=simp[by.t-D[t,vy]-t.ay];
 curv=simp[D[bx,vy]-D[by,vx]+bx.by-by.bx];
 dl=FindConstantDLog[bx,by,letters,vars];
 res=<|"Dimension"->n,"LeftInverseExactlyVerified"->AllTrue[Flatten[invLeft],SameQ[#,0]&],
 "RightInverseExactlyVerified"->AllTrue[Flatten[invRight],SameQ[#,0]&],
 "XGaugeIdentityExactlyVerified"->AllTrue[Flatten[gx],SameQ[#,0]&],
 "YGaugeIdentityExactlyVerified"->AllTrue[Flatten[gy],SameQ[#,0]&],
 "SymbolicCurvatureExactlyZero"->AllTrue[Flatten[curv],SameQ[#,0]&],
 "ConstantDLogExactlyVerified"->If[AssociationQ[dl],TrueQ[dl["Passed"]&&dl["ConstantResidues"]],False],
 "DLogData"->dl,"Convention"->"J=T.I; B_z=(partial_z T+T.A_z).TInverse"|>;
 AssociateTo[res,"Passed"->AllTrue[Values[KeyTake[res,{"LeftInverseExactlyVerified","RightInverseExactlyVerified","XGaugeIdentityExactlyVerified","YGaugeIdentityExactlyVerified","SymbolicCurvatureExactlyZero","ConstantDLogExactlyVerified"}]],TrueQ]];
 res
];
Clear[RationalPrimitivePart];
RationalPrimitivePart[expr_,z_]:=Module[{f=Together[expr],h=0,den,fac,repeat,p,k,q,num,inv,s,term,poly,iter=0},
 While[True,
  den=Denominator[f];fac=Rest[FactorList[den]];repeat=Select[fac,!FreeQ[#[[1]],z]&&#[[2]]>1&];
  If[repeat==={},Break[]];
  {p,k}=First[repeat];q=Cancel[den/p^k];num=Numerator[f];
  inv=Last[PolynomialExtendedGCD[q D[p,z],p,z]][[1]];
  s=Factor[PolynomialRemainder[-num inv/(k-1),p,z]];
  term=s/p^(k-1);h=Factor[h+term];f=Together[f-D[term,z]];
  iter++;If[iter>100,Return[Failure["HermiteIterationCap",<|"Residual"->f,"Primitive"->h|>]]];
 ];
 den=Denominator[f];num=Numerator[f];poly=PolynomialQuotient[num,den,z];
 If[poly=!=0,h=Factor[h+Sum[Coefficient[poly,z,j] z^(j+1)/(j+1),{j,0,Exponent[poly,z]}]]];h
];

End[];
EndPackage[];
