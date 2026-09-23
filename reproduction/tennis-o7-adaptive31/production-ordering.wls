(* O7: exact group and descending key order from FFIBPReductiond6Prop.wl. *)
Begin["ConformalIBP`Private`"];
fileGroup[a_]:=Switch[Boole[#>0]& /@ a[[{13,14,15}]],{1,0,0},1,{0,1,0},2,{0,0,0},3,_,0];
$fileSectorWeights={
 {1,1,1000,1,1000,1,1,1000,1000,1000,1,1,1,1,1,1,1,1},
 {1,1,1000,1,1000,1,1,1,1,1,1,1,1,1000,1000,1,1,1},
 {1,1,1,1,1,1,1,1000,1,1000,1,1,1000,1,1000,1,1,1}};
fileThreeKey[a_]:=Module[{s=Boole[#>0]& /@ a,b=fileGroup[a],k},
 k={Max[a[[{13,14,15}]]],Abs[a[[{13,14,15}]]].{1,2,3},Total[s],FromDigits[s,2],-Count[a,0],Max[Abs[a]],Abs[a].Join[ConstantArray[1,12],{2,2,2},{0,0,0}]};
 If[b<3,k=Prepend[k,s.$fileSectorWeights[[b+1]]]];
 {b,-k,-a}];
fileTwoKey[a_]:=Module[{s=Boole[#>0]& /@ a},Join[-{Total[s],FromDigits[s,2],-Count[a,0],Max[Abs[a]],Abs[a].{1,1,1,1,1,1,1,1,2,0,0}},{-a}]];
Clear[simpleKey];simpleKey[f_,g_G]:=fileThreeKey[List@@g];
fileBoundaryKey[BoundaryIntegral[2,a_List]]:={0,fileTwoKey[a]};
fileBoundaryKey[z_]:={1,z};
Clear[sources];sources[e_]:=SortBy[Union[Cases[{e},_BoundaryIntegral,Infinity]],fileBoundaryKey];
End[];
