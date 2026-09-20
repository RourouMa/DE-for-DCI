root=DirectoryName[DirectoryName[$InputFileName]];
Get[FileNameJoin[{root,"Kernel","ConformalIBP.wl"}]];
Get[FileNameJoin[{root,"Examples","kinematics.wl"}]];
families=Table[LadderFamily[l,kinematics,{x,y}],{l,1,4}];
f2=families[[2]];
AppendTo[families,CreateFamily[Join[KeyDrop[f2,{"Hash"}],
 <|"Propagators"->Reverse[f2["Propagators"]],"TopSector"->Reverse[f2["TopSector"]]|>]]];
passed=0;
Do[p=FamilyPropagators[f];a=Array[index,Length[p]];g=G@@a;
 Do[rule=Join[Thread[f["Loops"]->f["Loops"][[lp]]],Thread[f["External"]->f["External"][[ep]]]];
  ids=First[FirstPosition[p,#]]& /@ (p/.rule);
  expected=G@@ReplacePart[ConstantArray[0,Length[a]],Thread[ids->a]];
  actual=ConformalIBP`Private`relabel[f,g,rule];
  If[actual=!=expected || ConformalIBP`Private`relabel[f,g,rule]=!=expected,
   Print["FAIL ",f["Name"]," ",rule];Quit[1]];
  passed++,{lp,Permutations[Range[f["LoopCount"]]]},{ep,f["ExternalPermutations"]}],{f,families}];
Print[<|"FormalIndexPermutationChecks"->passed,"AllEqualToUncachedMapping"->True|>];Quit[0];
