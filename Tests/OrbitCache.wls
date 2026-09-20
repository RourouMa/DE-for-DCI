(* Compare against a trusted pre-orbit-cache package on actual centers and
   independently transformed factor blocks, including images outside a domain. *)
root=DirectoryName[DirectoryName[$InputFileName]];
args=Take[If[Length[$ScriptCommandLine]>=3,$ScriptCommandLine,$CommandLine],-2];
Get[First[args]];
DownValues[baselineCanonMemo]=DownValues[ConformalIBP`Private`canonMemo] /.
 ConformalIBP`Private`canonMemo -> baselineCanonMemo;
Clear[ConformalIBP`Private`canonMemo];
Get[FileNameJoin[{root,"Kernel","ConformalIBP.wl"}]];
job=Get[Last[args]];f=CreateFamily[Join[job["Family"],<|"IntegralOrdering"->"Legacy"|>]];
samples=job["Targets"];
AppendTo[samples,G@@Join[ConstantArray[1,Length[f["External"]] f["LoopCount"]],
 ConstantArray[0,Length[f["LoopLoopIDs"]]],ConstantArray[1,f["LoopCount"]]]];
externalImage[g_,offset_]:=Module[{a=List@@g,b=List@@g,blocks=ConformalIBP`Private`parts[f,g],ep,ids},
 Do[ep=f["ExternalPermutations"][[1+Mod[k+offset,Length[f["ExternalPermutations"]]]]];
  Do[ids=Table[First[FirstPosition[f["Propagators"],SP[x,f["Loops"][[i]]]]],{x,f["External"]}];
   b[[ids]]=a[[ids[[Ordering[ep]]]]],{i,blocks[[k]]}],{k,Length[blocks]}];G@@b];
images=Union[Flatten[Table[{g,externalImage[g,0],externalImage[g,1],
 ConformalIBP`Private`relabel[f,externalImage[g,2],Thread[f["Loops"]->Reverse[f["Loops"]]]]},
 {g,samples}],1]];
passed=0;
Do[old=baselineCanonMemo[f["Hash"],f,g];fresh=CanonicalIntegral[f,g];
 If[!MatchQ[fresh,_G] || old=!=fresh,Print["FAIL ",g," ",old," ",fresh];Quit[1]];
 passed++,{g,images}];
Print[<|"CanonicalImagesCompared"->passed,"ExactBaselineEquality"->True,
 "CachedOrbitImages"->(Length[DownValues[ConformalIBP`Private`canonMemo]]-1)|>];Quit[0];
