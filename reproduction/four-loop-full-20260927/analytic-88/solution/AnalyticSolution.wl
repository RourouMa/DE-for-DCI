(* Load once with Get. Every native integral is then individually indexable.
   All variables are explicitly namespaced to avoid PLT x/y shadowing. *)
Module[{base=DirectoryName[$InputFileName],canonical,native},
 canonical=Get[FileNameJoin[{base,"CanonicalFunctionsExplicit88.wl"}]];
 native=Get[FileNameJoin[{base,"NativeFunctions88.wl"}]];
 DCIAnalytic`$CanonicalFunctions88=canonical;
 DCIAnalytic`$NativeFunctions88=native;
 DCIAnalytic`Integral[i_Integer /; 1<=i<=88]:=DCIAnalytic`$NativeFunctions88[[i]];
 DCIAnalytic`Integral[i_Integer /; 1<=i<=88,xx_,yy_]:=DCIAnalytic`$NativeFunctions88[[i]]/.{DCIAnalytic`x->xx,DCIAnalytic`y->yy};
 DCIAnalytic`CanonicalIntegral[i_Integer /; 1<=i<=88]:=DCIAnalytic`$CanonicalFunctions88[[i]];
 DCIAnalytic`CanonicalIntegral[i_Integer /; 1<=i<=88,xx_,yy_]:=DCIAnalytic`$CanonicalFunctions88[[i]]/.{DCIAnalytic`x->xx,DCIAnalytic`y->yy};
 DCIAnalytic`GPL[{},z_]:=1;
 DCIAnalytic`GPLRootSum[{},z_]:=1;
 DCIAnalytic`YShiftedRoots[xx_]:=With[{c=xx^(1/3),w=(-1+I Sqrt[3])/2},
  {{0},{1},{2},{1-xx},{1+xx},{1-1/xx},{1+1/xx},
   {1-Sqrt[xx],1+Sqrt[xx]},{1-I Sqrt[xx],1+I Sqrt[xx]},
   {1-1/Sqrt[xx],1+1/Sqrt[xx]},{1-I/Sqrt[xx],1+I/Sqrt[xx]},
   {1-c,1-w c,1-w^2 c},{1+c,1+w c,1+w^2 c},
   {1-1/c,1-w/c,1-w^2/c},{1+1/c,1+w/c,1+w^2/c}}];
 DCIAnalytic`ToGPL[expr_]:=expr/.{
  DCIAnalytic`ChenX[word_List,xx_]:>DCIAnalytic`GPL[{1,0,2}[[word]],1-xx],
  DCIAnalytic`ChenY[word_List,xx_,yy_]:>DCIAnalytic`GPLRootSum[DCIAnalytic`YShiftedRoots[xx][[word]],1-yy]};
 DCIAnalytic`ExpandGPLRootSums[expr_]:=expr/.DCIAnalytic`GPLRootSum[sets_List,z_]:>Total[DCIAnalytic`GPL[#,z]& /@Tuples[sets]];
 <|"Dimension"->88,"Variables"->{DCIAnalytic`x,DCIAnalytic`y},
   "OriginalFourLoopIndices"->Range[53],"OriginalFull83Indices"->Range[83],
   "AdditionalClosureIndices"->Range[84,88],
   "NativeFunctions"->native,"CanonicalFunctions"->canonical,
   "Integral"->DCIAnalytic`Integral,"CanonicalIntegral"->DCIAnalytic`CanonicalIntegral,
   "ToGPL"->DCIAnalytic`ToGPL,"ExpandGPLRootSums"->DCIAnalytic`ExpandGPLRootSums,
   "Path"->"(1,1) -> (x,1) -> (x,y)","InitialDomain"->"0 < x < y^3 < 1",
   "MaximumChenWordLength"->8,"UnknownIntegrationConstants"->0,
   "Constants"->{Pi,Log[2],Zeta[3],PolyLog[4,1/2]},
   "GPLConvention"->"G({},z)=1; G({a,w},z)=Integral_0^z dt/(t-a) G(w,t). GPLRootSum is the finite Cartesian sum over the listed letter sets.",
   "ChenConvention"->"Words are outermost-first. X kernels dlog{x,1-x,1+x}, Y kernels are ChenResidues.wl YLetters; both start at 1. Integer word labels are 1-based."|>
]
