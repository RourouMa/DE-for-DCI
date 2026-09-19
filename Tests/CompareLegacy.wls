(* Optional local comparison: supply the original IBP4loop.wl as the final argument. *)
source=Last[If[Length[$ScriptCommandLine]>=2,$ScriptCommandLine,$CommandLine]];
If[!FileExistsQ[source] || FileNameTake[source]=!="IBP4loop.wl",Print["Supply a trusted original IBP4loop.wl path."];Quit[2]];
Begin["Legacy`"];
Get[Global`source];
End[];
Get[FileNameJoin[{DirectoryName[DirectoryName[$InputFileName]],"Kernel","ConformalIBP.wl"}]];
kin={SP[X1,X1]->2 x,SP[X3,X3]->2 x,SP[X2,X2]->2 y,SP[X4,X4]->2 y,
 SP[X1,X3]->1+x^2,SP[X2,X4]->1+y^2,SP[X1,X2]->0,SP[X1,X4]->0,SP[X2,X3]->0,SP[X3,X4]->0};
f=LadderFamily[4,kin,{x,y}];
vectors=Join[f["External"],f["Loops"],{x,y}];legacyVectors=Symbol["Legacy`"<>SymbolName[#]]& /@ vectors;
toOld=Thread[vectors->legacyVectors];toNew=Join[Thread[legacyVectors->vectors],{Legacy`sp->SP,Legacy`inf->ConformalIBP`Private`infinity}];
top=G@@Join[f["TopSector"],{1,1,1,1}];
factor=G[2,-1,-1,2,0,2,0,0,0,1,0,3,0,0,1,3,2,0,0,0,0,0,1,1,1,1];
plan=GenerateSeeds[f,{top}];ops=plan["Operators"];
cases=Cases[Table[If[batch["Seeds"]==={},Nothing,{ops[[batch["OperatorIndex"]]],First[batch["Seeds"]]}],{batch,plan["Batches"]}],_List];
cases=Join[Take[cases,UpTo[18]],Table[{op,factor},{op,Select[ops,#["Degree"]==={0,0,0,0}&]}]];
passed=0;rejected=0;
Do[op=case[[1]];seed=case[[2]];yi=f["Loops"][[op["Loop"]]];
 oldOp=((SP[yi,op["A"]] Legacy`v[op["B"]]-SP[yi,op["B"]] Legacy`v[op["A"]]) Legacy`d[yi]/.SP->Legacy`sp)/.toOld;
 old=Legacy`Operator2IBPRat[oldOp,Legacy`Propagators4,Legacy`G@@(List@@seed)];
 old=Together[((old Times@@Legacy`DeltaPropagators/.Legacy`Kinematics)/.toNew)/.Thread[f["DeltaPropagators"]->0]];
 contact=ConformalIBP`Private`contacts[f,op,seed];
 If[FailureQ[contact],rejected++;Continue[]];
 fresh=Together[ConformalIBP`Private`ordinary[f,op,seed]+contact];
 If[!TrueQ[Together[old-fresh]===0],Print["FAIL ",case];Print[InputForm[Together[old-fresh]]];Quit[1]];
 passed++,{case,cases}];
Print[<|"LegacyRawActionMatches"->passed,"ExplicitUnsupportedContacts"->rejected|>];Quit[0];
