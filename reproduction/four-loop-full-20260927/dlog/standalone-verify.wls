(* Place next to Full88DLog.wl, under the directory containing original A_x/A_y.
   WolframKernel -script standalone-verify.wls
   This check needs no FiniteFlow, original IBP pool, or ConformalIBP package. *)
$IterationLimit=Infinity;
out=DirectoryName[$InputFileName];native=DirectoryName[out];
c=Get[FileNameJoin[{out,"Full88DLog.wl"}]];
t=c["NativeToNew"];ti=c["NewToNative"];{bx,by}=c["Matrices"];
letters=c["Letters"];rs=c["ResidueMatrices"];n=Length[t];
ax=Get[FileNameJoin[{native,"A_x.wl"}]];ay=Get[FileNameJoin[{native,"A_y.wl"}]];
zero[m_]:=AllTrue[Flatten[m],SameQ[Cancel[Together[#]],0]&];
checks=<|"Dimension"->n,"RationalGaugeLeftInverse"->zero[t.ti-IdentityMatrix[n]],
"RationalGaugeRightInverse"->zero[ti.t-IdentityMatrix[n]],
"XGaugeIdentity"->zero[D[t,x]+t.ax-bx.t],
"YGaugeIdentity"->zero[D[t,y]+t.ay-by.t],
"ConstantResidues"->FreeQ[rs,x|y],
"XConstantDLog"->zero[bx-Sum[rs[[a]]D[letters[[a]],x]/letters[[a]],{a,Length[letters]}]],
"YConstantDLog"->zero[by-Sum[rs[[a]]D[letters[[a]],y]/letters[[a]],{a,Length[letters]}]],
"ExactCurvature"->zero[D[bx,y]-D[by,x]+bx.by-by.bx],
"CandidateSHA256"->FileHash[FileNameJoin[{out,"Full88DLog.wl"}],"SHA256"],
"NativeAxSHA256"->FileHash[FileNameJoin[{native,"A_x.wl"}],"SHA256"],
"NativeAySHA256"->FileHash[FileNameJoin[{native,"A_y.wl"}],"SHA256"]|>;
passed=AllTrue[Values[KeyTake[checks,{"RationalGaugeLeftInverse","RationalGaugeRightInverse","XGaugeIdentity","YGaugeIdentity","ConstantResidues","XConstantDLog","YConstantDLog","ExactCurvature"}]],TrueQ];
AssociateTo[checks,"Passed"->passed];Print[checks];
Export[FileNameJoin[{out,"Recheck.json"}],checks,"RawJSON"];Quit[If[passed,0,1]];
